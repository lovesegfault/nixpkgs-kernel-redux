#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (p: with p; [ requests pgpy tqdm ])"

import hashlib
import json
import logging
import warnings
from base64 import b64encode
from pathlib import Path
from typing import Any, Dict
from urllib.parse import urlsplit, urlunsplit

import requests
from pgpy import PGPKey, PGPMessage
from tqdm import tqdm


def fetch_releases() -> dict:
    text = requests.get("https://kernel.org/releases.json").text
    parsed: Dict[str, Any] = json.loads(text)
    logging.info("Fetched kernel releases")
    # remove fields we don't care about
    for release in parsed["releases"]:
        release.pop("diffview", None)
        release.pop("gitweb", None)
        release.pop("patch", None)
        release.pop("pgp", None)
        release.pop("released", None)
    return parsed


def format_sri(algo: str, hex: str) -> str:
    hash = b64encode(bytes.fromhex(hex)).decode()
    return f"{algo}-{hash}"


autosigner_key: PGPKey | None = None


def verify_shasums_sig(blob: str) -> str:
    global autosigner_key
    if autosigner_key is None:
        key_path = Path(__file__).parent / "autosigner.gpg"
        key_blob = key_path.read_text()
        autosigner_key = PGPKey()
        autosigner_key.parse(data=key_blob)
    message = PGPMessage()
    message.parse(blob)
    # NOTE: PGPy is annoying about some verification features not being
    # implemented, but I think it doesn't apply to what we do here.
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        if not autosigner_key.verify(message):
            raise Exception("Failed to verify signature of sha256sums.asc")
    return str(message.message)


release_shasums = dict()


def fetch_shasums(release: Dict[str, Any]) -> str:
    global release_shasums
    source_url = urlsplit(release["source"])
    source_path = Path(source_url.path)
    source_name = source_path.name
    shasums_url = source_url._replace(path=str(source_path.with_name("sha256sums.asc")))
    shasums_url = urlunsplit(shasums_url)
    if shasums_url not in release_shasums:
        shasums = requests.get(shasums_url).text
        try:
            shasums = verify_shasums_sig(shasums)
        except Exception as e:
            raise Exception(f"Failed to fetch {shasums_url}") from e
        release_shasums[shasums_url] = shasums

    logging.debug(f"Got shasums for {source_name}")
    return release_shasums[shasums_url]


def get_source_hashes(releases: dict) -> None:
    for release in releases["releases"]:
        source = release["source"]
        if source is None:
            if release["moniker"] != "linux-next":
                raise Exception(
                    f"Release has no source, but is not linux-next: {release}"
                )
            fetch_linux_next(release)
            continue

        source_url = urlsplit(release["source"])
        source_path = Path(source_url.path)
        source_name = source_path.name

        source_hash = None
        shasums = fetch_shasums(release)
        for line in shasums.splitlines():
            # skip empty lines
            if not line:
                continue
            # lines are of form "hash  source_name"
            # NOTE: the double space is load-bearing
            (hash, name) = line.split("  ")
            if name == source_name:
                source_hash = hash
                break

        if source_hash is None:
            raise Exception(f"Failed to parse hash for {source_name}")

        release["hash"] = format_sri("sha256", source_hash)
        logging.info(f"{source_name}: {release['hash']}")


def fetch_linux_next(release: Dict[str, Any]):
    version = release["version"]
    source_name = f"linux-next-{version}.tar.gz"

    source = f"https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/snapshot/{source_name}"  # noqa: E501
    logging.info(f"Prefetching {source_name} snapshot, this may take a while")

    hash = hashlib.sha256()
    with requests.get(source, stream=True) as stream:
        source_size = int(stream.headers.get("content-length", 0))
        chunk_size = 1024
        logging.debug(f"{source_name} is expected to be {source_size} bytes")
        with tqdm(
            desc=source_name,
            total=source_size,
            unit="B",
            unit_scale=True,
            unit_divisor=chunk_size,
        ) as bar:
            for chunk in stream.iter_content(chunk_size=chunk_size):
                hash.update(chunk)
                bar.update(chunk_size)

    source_hash = format_sri("sha256", hash.hexdigest())
    release["source"] = source
    release["hash"] = source_hash
    logging.info(f"{source_name}: {source_hash}")


def main():
    logging.basicConfig(level=logging.INFO)
    releases = fetch_releases()
    get_source_hashes(releases)

    releases_path = Path(__file__).parent / "releases.json"
    releases_path.write_text(json.dumps(releases, indent=2))


if __name__ == "__main__":
    main()
