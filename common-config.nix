# WARNING/NOTE: whenever you want to add an here you need to either
# * mark it as an optional one with `option`,
# * or make sure it works for all the versions in nixpkgs,
# * or check for which kernel versions it will work (using kernel
#   changelog, google or whatever) and mark it with `whenOlder` or
#   `whenAtLeast`.
# Then do test your change by building all the kernels (or at least
# their configs) in Nixpkgs or else you will guarantee lots and lots
# of pain to users trying to switch to an older kernel because of some
# hardware problems with a new one.

# Configuration
{ lib
, stdenv
, version
}:

with lib;
with lib.kernel;
with (lib.kernel.whenHelpers version);

let
  # configuration items have to be part of a subattrs
  flattenKConf = nested: mapAttrs (_: head) (zipAttrs (attrValues nested));

  whenPlatformHasEBPFJit =
    mkIf (stdenv.hostPlatform.isAarch32 ||
      stdenv.hostPlatform.isAarch64 ||
      stdenv.hostPlatform.isx86_64 ||
      (stdenv.hostPlatform.isPower && stdenv.hostPlatform.is64bit) ||
      (stdenv.hostPlatform.isMips && stdenv.hostPlatform.is64bit));

  options = {

    debug = {
      # Necessary for BTF
      DEBUG_INFO = mkMerge [
        (whenOlder "5.2" "n")
        (whenBetween "5.2" "5.18" "y")
      ];
      DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT = whenAtLeast "5.18" "y";
      DEBUG_INFO_BTF = whenAtLeast "5.2" "y";
      DEBUG_INFO_REDUCED = whenAtLeast "5.13" "n"; # conflicts with BTF
      DEBUG_INFO_SPLIT = whenAtLeast "5.2" "n"; # conflicts with BTF
      # Allow loading modules with mismatched BTFs
      # FIXME: figure out how to actually make BTFs reproducible instead
      # See https://github.com/NixOS/nixpkgs/pull/181456 for details.
      MODULE_ALLOW_BTF_MISMATCH = whenAtLeast "5.18" "y";
      BPF_LSM = whenAtLeast "5.7" "y";
      DEBUG_KERNEL = "y";
      DEBUG_DEVRES = "n";
      DYNAMIC_DEBUG = "y";
      TIMER_STATS = whenOlder "4.11" "y";
      DEBUG_NX_TEST = whenOlder "4.11" "n";
      DEBUG_STACK_USAGE = "n";
      DEBUG_STACKOVERFLOW = "n";
      RCU_TORTURE_TEST = "n";
      # FIXME: Why can't we disable this?
      # SCHEDSTATS = "n";
      DETECT_HUNG_TASK = "y";
      CRASH_DUMP = "n";
      # Easier debugging of NFS issues.
      SUNRPC_DEBUG = "y";
      # Provide access to tunables like sched_migration_cost_ns
      SCHED_DEBUG = "y";
    };

    power-management = {
      CPU_FREQ_DEFAULT_GOV_PERFORMANCE = "y";
      CPU_FREQ_GOV_SCHEDUTIL = "y";
      PM_ADVANCED_DEBUG = "y";
      PM_WAKELOCKS = "y";
      POWERCAP = "y";
    } // optionalAttrs stdenv.hostPlatform.isx86 {
      INTEL_IDLE = "y";
      INTEL_RAPL = whenAtLeast "5.3" "m";
      X86_INTEL_LPSS = "y";
      X86_INTEL_PSTATE = "y";
    };

    external-firmware = {
      # Support drivers that need external firmware.
      STANDALONE = "n";
    };

    proc-config-gz = {
      # Make /proc/config.gz available
      IKCONFIG = "y";
      IKCONFIG_PROC = "y";
    };

    optimization = {
      # Optimize with -O2, not -Os
      CC_OPTIMIZE_FOR_SIZE = "n";
    };

    memtest = {
      MEMTEST = "y";
    };

    # Include the CFQ I/O scheduler in the kernel, rather than as a
    # "m", so that the initrd gets a good I/O scheduler.
    scheduler = {
      IOSCHED_CFQ = whenOlder "5.0" "y"; # Removed in 5.0-RC1
      BLK_CGROUP = "y"; # required by CFQ"
      BLK_CGROUP_IOLATENCY = whenAtLeast "4.19" "y";
      BLK_CGROUP_IOCOST = whenAtLeast "5.4" "y";
      IOSCHED_DEADLINE = whenOlder "5.0" "y"; # Removed in 5.0-RC1
      MQ_IOSCHED_DEADLINE = whenAtLeast "4.11" "y";
      BFQ_GROUP_IOSCHED = whenAtLeast "4.12" "y";
      MQ_IOSCHED_KYBER = whenAtLeast "4.12" "y";
      IOSCHED_BFQ = whenAtLeast "4.12" "m";
    };

    # Enable NUMA.
    numa = {
      NUMA = "y";
    };

    networking = {
      NET = "y";
      IP_ADVANCED_ROUTER = "y";
      IP_PNP = "n";
      IP_VS_PROTO_TCP = "y";
      IP_VS_PROTO_UDP = "y";
      IP_VS_PROTO_ESP = "y";
      IP_VS_PROTO_AH = "y";
      IP_VS_IPV6 = "y";
      IP_DCCP_CCID3 = "n"; # experimental
      CLS_U32_PERF = "y";
      CLS_U32_MARK = "y";
      BPF_JIT = whenPlatformHasEBPFJit "y";
      BPF_JIT_ALWAYS_ON = whenPlatformHasEBPFJit "n"; # whenPlatformHasEBPFJit "y"; # see https://github.com/NixOS/nixpkgs/issues/79304
      HAVE_EBPF_JIT = whenPlatformHasEBPFJit "y";
      BPF_STREAM_PARSER = whenAtLeast "4.19" "y";
      XDP_SOCKETS = whenAtLeast "4.19" "y";
      XDP_SOCKETS_DIAG = whenAtLeast "5.1" "y";
      WAN = "y";
      TCP_CONG_ADVANCED = "y";
      TCP_CONG_CUBIC = "y"; # This is the default congestion control algorithm since 2.6.19
      # Required by systemd per-cgroup firewalling
      CGROUP_BPF = "y";
      CGROUP_NET_PRIO = "y"; # Required by systemd
      IP_ROUTE_VERBOSE = "y";
      IP_MROUTE_MULTIPLE_TABLES = "y";
      IP_MULTICAST = "y";
      IP_MULTIPLE_TABLES = "y";
      IPV6 = "y";
      IPV6_ROUTER_PREF = "y";
      IPV6_ROUTE_INFO = "y";
      IPV6_OPTIMISTIC_DAD = "y";
      IPV6_MULTIPLE_TABLES = "y";
      IPV6_SUBTREES = "y";
      IPV6_MROUTE = "y";
      IPV6_MROUTE_MULTIPLE_TABLES = "y";
      IPV6_PIMSM_V2 = "y";
      IPV6_FOU_TUNNEL = "m";
      IPV6_SEG6_LWTUNNEL = whenAtLeast "4.10" "y";
      IPV6_SEG6_HMAC = whenAtLeast "4.10" "y";
      IPV6_SEG6_BPF = whenAtLeast "4.18" "y";
      NET_CLS_BPF = "m";
      NET_ACT_BPF = "m";
      NET_SCHED = "y";
      L2TP_V3 = "y";
      L2TP_IP = "m";
      L2TP_ETH = "m";
      BRIDGE_VLAN_FILTERING = "y";
      BONDING = "m";
      NET_L3_MASTER_DEV = "y";
      NET_FOU_IP_TUNNELS = "y";
      IP_NF_TARGET_REDIRECT = "m";

      PPP_MULTILINK = "y"; # PPP multilink support
      PPP_FILTER = "y";

      # needed for iwd WPS support (wpa_supplicant replacement)
      KEY_DH_OPERATIONS = "y";

      # needed for nftables
      # Networking Options
      NETFILTER = "y";
      NETFILTER_ADVANCED = "y";
      # Core Netfilter Configuration
      NF_CONNTRACK_ZONES = "y";
      NF_CONNTRACK_EVENTS = "y";
      NF_CONNTRACK_TIMEOUT = "y";
      NF_CONNTRACK_TIMESTAMP = "y";
      NETFILTER_NETLINK_GLUE_CT = "y";
      NF_TABLES_INET = mkMerge [
        (whenOlder "4.17" "m")
        (whenAtLeast "4.17" "y")
      ];
      NF_TABLES_NETDEV = mkMerge [
        (whenOlder "4.17" "m")
        (whenAtLeast "4.17" "y")
      ];
      NFT_REJECT_NETDEV = whenAtLeast "5.11" "m";

      # IP: Netfilter Configuration
      NF_TABLES_IPV4 = mkMerge [
        (whenOlder "4.17" "m")
        (whenAtLeast "4.17" "y")
      ];
      NF_TABLES_ARP = mkMerge [
        (whenOlder "4.17" "m")
        (whenAtLeast "4.17" "y")
      ];
      # IPv6: Netfilter Configuration
      NF_TABLES_IPV6 = mkMerge [
        (whenOlder "4.17" "m")
        (whenAtLeast "4.17" "y")
      ];
      # Bridge Netfilter Configuration
      NF_TABLES_BRIDGE = mkMerge [
        (whenBetween "4.19" "5.3" "y")
        (whenAtLeast "5.3" "m")
      ];

      # needed for `dropwatch`
      # Builtin-only since https://github.com/torvalds/linux/commit/f4b6bcc7002f0e3a3428bac33cf1945abff95450
      NET_DROP_MONITOR = "y";

      # needed for ss
      # Use a lower priority to allow these options to be overridden in hardened/config.nix
      INET_DIAG = mkDefault "m";
      INET_TCP_DIAG = mkDefault "m";
      INET_UDP_DIAG = mkDefault "m";
      INET_RAW_DIAG = whenAtLeast "4.14" (mkDefault "m");
      INET_DIAG_DESTROY = mkDefault "y";

      # enable multipath-tcp
      MPTCP = whenAtLeast "5.6" "y";
      MPTCP_IPV6 = whenAtLeast "5.6" "y";
      INET_MPTCP_DIAG = whenAtLeast "5.9" (mkDefault "m");

      # Kernel TLS
      TLS = whenAtLeast "4.13" "m";
      TLS_DEVICE = whenAtLeast "4.18" "y";

      # infiniband
      INFINIBAND = "m";
      INFINIBAND_IPOIB = "m";
      INFINIBAND_IPOIB_CM = "y";
    };

    wireless = {
      CFG80211_WEXT = "y"; # Without it, ipw2200 drivers don't build
      IPW2100_MONITOR = "y"; # support promiscuous mode
      IPW2200_MONITOR = "y"; # support promiscuous mode
      HOSTAP_FIRMWARE = "y"; # Support downloading firmware images with Host AP driver
      HOSTAP_FIRMWARE_NVRAM = "y";
      ATH9K_PCI = "y"; # Detect Atheros AR9xxx cards on PCI(e) bus
      ATH9K_AHB = "y"; # Ditto, AHB bus
      B43_PHY_HT = "y";
      BCMA_HOST_PCI = "y";
      RTW88 = whenAtLeast "5.2" "m";
      RTW88_8822BE = mkMerge [ (whenBetween "5.2" "5.8" "y") (whenAtLeast "5.8" "m") ];
      RTW88_8822CE = mkMerge [ (whenBetween "5.2" "5.8" "y") (whenAtLeast "5.8" "m") ];
    };

    fb = {
      FB = "y";
      FB_EFI = "y";
      FB_NVIDIA_I2C = "y"; # Enable DDC Support
      FB_RIVA_I2C = "y";
      FB_ATY_CT = "y"; # Mach64 CT/VT/GT/LT (incl. 3D RAGE) support
      FB_ATY_GX = "y"; # Mach64 GX support
      FB_SAVAGE_I2C = "y";
      FB_SAVAGE_ACCEL = "y";
      FB_SIS_300 = "y";
      FB_SIS_315 = "y";
      FB_3DFX_ACCEL = "y";
      FB_VESA = "y";
      FRAMEBUFFER_CONSOLE = "y";
      FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER = whenAtLeast "4.19" "y";
      FRAMEBUFFER_CONSOLE_ROTATION = "y";
      FB_GEODE = mkIf (stdenv.hostPlatform.system == "i686-linux") "y";
      # On 5.14 this conflicts with FB_SIMPLE.
      DRM_SIMPLEDRM = whenAtLeast "5.14" "n";
    };

    video = {
      DRM_LEGACY = "n";
      NOUVEAU_LEGACY_CTX_SUPPORT = whenAtLeast "5.2" "n";

      # Allow specifying custom EDID on the kernel command line
      DRM_LOAD_EDID_FIRMWARE = "y";
      VGA_SWITCHEROO = "y"; # Hybrid graphics support
      DRM_GMA500 = whenAtLeast "5.12" "m";
      DRM_GMA600 = whenOlder "5.13" "y";
      DRM_GMA3600 = whenOlder "5.12" "y";
      DRM_VMWGFX_FBCON = "y";
      # (experimental) amdgpu support for verde and newer chipsets
      DRM_AMDGPU_SI = "y";
      # (stable) amdgpu support for bonaire and newer chipsets
      DRM_AMDGPU_CIK = "y";
      # Allow device firmware updates
      DRM_DP_AUX_CHARDEV = "y";
      # amdgpu display core (DC) support
      DRM_AMD_DC_DCN1_0 = whenBetween "4.15" "5.6" "y";
      DRM_AMD_DC_PRE_VEGA = whenBetween "4.15" "4.18" "y";
      DRM_AMD_DC_DCN2_0 = whenBetween "5.3" "5.6" "y";
      DRM_AMD_DC_DCN2_1 = whenBetween "5.4" "5.6" "y";
      DRM_AMD_DC_DCN3_0 = whenBetween "5.9" "5.11" "y";
      DRM_AMD_DC_DCN = whenAtLeast "5.11" "y";
      DRM_AMD_DC_HDCP = whenAtLeast "5.5" "y";
      DRM_AMD_DC_SI = whenAtLeast "5.10" "y";
    } // optionalAttrs (stdenv.hostPlatform.system == "x86_64-linux") {
      # Intel GVT-g graphics virtualization supports 64-bit only
      DRM_I915_GVT = whenAtLeast "4.16" "y";
      DRM_I915_GVT_KVMGT = whenAtLeast "4.16" "m";
    } // optionalAttrs (stdenv.hostPlatform.system == "aarch64-linux") {
      # enable HDMI-CEC on RPi boards
      DRM_VC4_HDMI_CEC = whenAtLeast "4.14" "y";
    };

    sound = {
      SND_DYNAMIC_MINORS = "y";
      SND_AC97_POWER_SAVE = "y"; # AC97 Power-Saving Mode
      SND_HDA_INPUT_BEEP = "y"; # Support digital beep via input layer
      SND_HDA_RECONFIG = "y"; # Support reconfiguration of jack functions
      # Support configuring jack functions via fw mechanism at boot
      SND_HDA_PATCH_LOADER = "y";
      SND_HDA_CODEC_CA0132_DSP = whenOlder "5.7" "y"; # Enable DSP firmware loading on Creative Soundblaster Z/Zx/ZxR/Recon
      SND_OSSEMUL = "y";
      SND_USB_CAIAQ_INPUT = "y";
      # Enable PSS mixer (Beethoven ADSP-16 and other compatible)
      PSS_MIXER = whenOlder "4.12" "y";
      # Enable Sound Open Firmware support
    } // optionalAttrs
      (stdenv.hostPlatform.system == "x86_64-linux" &&
        versionAtLeast version "5.5")
      {
        SND_SOC_INTEL_SOUNDWIRE_SOF_MACH = whenAtLeast "5.10" "m";
        SND_SOC_INTEL_USER_FRIENDLY_LONG_NAMES = whenAtLeast "5.10" "y"; # dep of SOF_MACH
        SND_SOC_SOF_INTEL_SOUNDWIRE_LINK = whenBetween "5.10" "5.11" "y"; # dep of SOF_MACH
        SND_SOC_SOF_TOPLEVEL = "y";
        SND_SOC_SOF_ACPI = "m";
        SND_SOC_SOF_PCI = "m";
        SND_SOC_SOF_APOLLOLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_APOLLOLAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_CANNONLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_CANNONLAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_COFFEELAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_COFFEELAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_COMETLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_COMETLAKE_H_SUPPORT = whenOlder "5.8" "y";
        SND_SOC_SOF_COMETLAKE_LP_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_ELKHARTLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_ELKHARTLAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_GEMINILAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_GEMINILAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_NOCODEC = whenAtLeast "5.12" "n";
        SND_SOC_SOF_NOCODEC_SUPPORT = whenAtLeast "5.12" "n";
        SND_SOC_SOF_HDA_AUDIO_CODEC = "y";
        SND_SOC_SOF_HDA_COMMON_HDMI_CODEC = whenOlder "5.7" "y";
        SND_SOC_SOF_HDA_LINK = "y";
        SND_SOC_SOF_ICELAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_ICELAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_INTEL_TOPLEVEL = "y";
        SND_SOC_SOF_JASPERLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_JASPERLAKE_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_MERRIFIELD = whenAtLeast "5.12" "m";
        SND_SOC_SOF_MERRIFIELD_SUPPORT = whenOlder "5.12" "y";
        SND_SOC_SOF_TIGERLAKE = whenAtLeast "5.12" "m";
        SND_SOC_SOF_TIGERLAKE_SUPPORT = whenOlder "5.12" "y";
      };

    usb-serial = {
      USB_SERIAL_GENERIC = "y"; # USB Generic Serial Driver
    } // optionalAttrs (versionOlder version "4.16") {
      # Include firmware for various USB serial devices.
      # Only applicable for kernels below 4.16, after that "n" firmware is shipped in the kernel tree.
      USB_SERIAL_KEYSPAN_MPR = "y";
      USB_SERIAL_KEYSPAN_USA28 = "y";
      USB_SERIAL_KEYSPAN_USA28X = "y";
      USB_SERIAL_KEYSPAN_USA28XA = "y";
      USB_SERIAL_KEYSPAN_USA28XB = "y";
      USB_SERIAL_KEYSPAN_USA19 = "y";
      USB_SERIAL_KEYSPAN_USA18X = "y";
      USB_SERIAL_KEYSPAN_USA19W = "y";
      USB_SERIAL_KEYSPAN_USA19QW = "y";
      USB_SERIAL_KEYSPAN_USA19QI = "y";
      USB_SERIAL_KEYSPAN_USA49W = "y";
      USB_SERIAL_KEYSPAN_USA49WLC = "y";
    };

    usb = {
      USB_DEBUG = whenOlder "4.18" "n";
      USB_EHCI_ROOT_HUB_TT = "y"; # Root Hub Transaction Translators
      USB_EHCI_TT_NEWSCHED = "y"; # Improved transaction translator scheduling
      USB_HIDDEV = "y"; # USB Raw HID Devices (like monitor controls and Uninterruptable Power Supplies)
    };

    # Filesystem options - in particular, enable extended attributes and
    # ACLs for all filesystems that support them.
    filesystem = {
      FANOTIFY = "y";
      TMPFS = "y";
      TMPFS_POSIX_ACL = "y";
      FS_ENCRYPTION = if versionAtLeast version "5.1" then "y" else whenAtLeast "4.9" "m";

      EXT2_FS_XATTR = "y";
      EXT2_FS_POSIX_ACL = "y";
      EXT2_FS_SECURITY = "y";

      EXT3_FS_POSIX_ACL = "y";
      EXT3_FS_SECURITY = "y";

      EXT4_FS_POSIX_ACL = "y";
      EXT4_FS_SECURITY = "y";
      EXT4_ENCRYPTION = whenBetween "4.8" "5.0" "y";

      NTFS_FS = whenAtLeast "5.15" "n";
      NTFS3_LZX_XPRESS = whenAtLeast "5.15" "y";
      NTFS3_FS_POSIX_ACL = whenAtLeast "5.15" "y";

      REISERFS_FS_XATTR = "y";
      REISERFS_FS_POSIX_ACL = "y";
      REISERFS_FS_SECURITY = "y";

      JFS_POSIX_ACL = "y";
      JFS_SECURITY = "y";

      XFS_QUOTA = "y";
      XFS_POSIX_ACL = "y";
      XFS_RT = "y"; # XFS Realtime subvolume support

      OCFS2_DEBUG_MASKLOG = "n";

      BTRFS_FS_POSIX_ACL = "y";

      UBIFS_FS_ADVANCED_COMPR = "y";

      F2FS_FS = "m";
      F2FS_FS_SECURITY = "y";
      F2FS_FS_ENCRYPTION = whenBetween "4.2" "5.0" "y";
      F2FS_FS_COMPRESSION = whenAtLeast "5.6" "y";
      UDF_FS = "m";

      NFSD_V2_ACL = "y";
      NFSD_V3 = whenOlder "5.18" "y";
      NFSD_V3_ACL = "y";
      NFSD_V4 = "y";
      NFSD_V4_SECURITY_LABEL = "y";

      NFS_FSCACHE = "y";
      NFS_SWAP = "y";
      NFS_V3_ACL = "y";
      NFS_V4_1 = "y"; # NFSv4.1 client support
      NFS_V4_2 = "y";
      NFS_V4_SECURITY_LABEL = "y";

      CIFS_XATTR = "y";
      CIFS_POSIX = "y";
      CIFS_FSCACHE = "y";
      CIFS_STATS = whenOlder "4.19" "y";
      CIFS_WEAK_PW_HASH = whenOlder "5.15" "y";
      CIFS_UPCALL = "y";
      CIFS_ACL = whenOlder "5.3" "y";
      CIFS_DFS_UPCALL = "y";
      CIFS_SMB2 = whenOlder "4.13" "y";

      CEPH_FSCACHE = "y";
      CEPH_FS_POSIX_ACL = "y";

      SQUASHFS_FILE_DIRECT = "y";
      SQUASHFS_DECOMP_MULTI_PERCPU = "y";
      SQUASHFS_XATTR = "y";
      SQUASHFS_ZLIB = "y";
      SQUASHFS_LZO = "y";
      SQUASHFS_XZ = "y";
      SQUASHFS_LZ4 = "y";
      SQUASHFS_ZSTD = whenAtLeast "4.14" "y";

      # Native Language Support modules, needed by some filesystems
      NLS = "y";
      NLS_DEFAULT = "utf8";
      NLS_UTF8 = "m";
      NLS_CODEPAGE_437 = "m"; # VFAT default for the codepage= mount option
      NLS_ISO8859_1 = "m"; # VFAT default for the iocharset= mount option

      # Needed to use the installation iso image. Not included in all defconfigs (e.g. arm64)
      ISO9660_FS = "m";

      DEVTMPFS = "y";

      UNICODE = whenAtLeast "5.2" "y"; # Casefolding support for filesystems
    };

    security = {
      FORTIFY_SOURCE = whenAtLeast "4.13" "y";

      # https://googleprojectzero.blogspot.com/2019/11/bad-binder-android-in-wild-exploit.html
      DEBUG_LIST = "y";
      # Detect writes to read-only "m" pages
      DEBUG_SET_MODULE_RONX = whenOlder "4.11" "y";
      HARDENED_USERCOPY = "y";
      RANDOMIZE_BASE = "y";
      STRICT_DEVMEM = mkDefault "y"; # Filter access to /dev/mem
      IO_STRICT_DEVMEM = mkDefault "y";
      SECURITY_SELINUX_BOOTPARAM_VALUE = whenOlder "5.1" "0"; # Disable SELinux by default
      # Prevent processes from ptracing non-children processes
      SECURITY_YAMA = "y";
      # The goal of Landlock is to enable to restrict ambient rights (e.g. global filesystem access) for a set of processes.
      # This does not have any effect if a program does not support it
      SECURITY_LANDLOCK = whenAtLeast "5.13" "y";
      DEVKMEM = whenOlder "5.13" "n"; # Disable /dev/kmem

      USER_NS = "y"; # Support for user namespaces

      SECURITY_APPARMOR = "y";
      DEFAULT_SECURITY_APPARMOR = "y";

      RANDOM_TRUST_CPU = whenAtLeast "4.19" "y"; # allow RDRAND to seed the RNG
      RANDOM_TRUST_BOOTLOADER = whenAtLeast "5.4" "y"; # allow the bootloader to seed the RNG

      MODULE_SIG = "n"; # r13y, generates a random key during build and bakes it in
      # Depends on MODULE_SIG and only really helps when you sign your modules
      # and enforce signatures which we don't do by default.
      SECURITY_LOCKDOWN_LSM = "n";

      # provides a register of persistent per-UID keyrings, useful for encrypting storage pools in stratis
      PERSISTENT_KEYRINGS = "y";
      # enable temporary caching of the last request_key() result
      KEYS_REQUEST_CACHE = whenAtLeast "5.3" "y";
    } // optionalAttrs (!stdenv.hostPlatform.isAarch32) {

      # Detect buffer overflows on the stack
      CC_STACKPROTECTOR_REGULAR = whenOlder "4.18" "y";
    } // optionalAttrs stdenv.hostPlatform.isx86_64 {
      # Enable Intel SGX
      X86_SGX = whenAtLeast "5.11" "y";
      # Allow KVM guests to load SGX enclaves
      X86_SGX_KVM = whenAtLeast "5.13" "y";
    };

    microcode = {
      MICROCODE = "y";
      MICROCODE_INTEL = "y";
      MICROCODE_AMD = "y";
    } // optionalAttrs (versionAtLeast version "4.10") {
      # Write Back Throttling
      # https://lwn.net/Articles/682582/
      # https://bugzilla.kernel.org/show_bug.cgi?id=12309#c655
      BLK_WBT = "y";
      BLK_WBT_SQ = whenOlder "5.0" "y"; # Removed in 5.0-RC1
      BLK_WBT_MQ = "y";
    };

    container = {
      NAMESPACES = "y"; #  Required by 'unshare' used by 'nixos-install'
      RT_GROUP_SCHED = "n";
      CGROUP_DEVICE = "y";
      CGROUP_HUGETLB = "y";
      CGROUP_PERF = "y";
      CGROUP_RDMA = whenAtLeast "4.11" "y";

      MEMCG = "y";
      MEMCG_SWAP = "y";

      BLK_DEV_THROTTLING = "y";
      CFQ_GROUP_IOSCHED = whenOlder "5.0" "y"; # Removed in 5.0-RC1
      CGROUP_PIDS = "y";
    };

    staging = {
      # Enable staging drivers.  These are somewhat experimental, but
      # they generally don't hurt.
      STAGING = "y";
    };

    proc-events = {
      # PROC_EVENTS requires that the netlink connector is not built
      # as a "m".  This is required by libcgroup's cgrulesengd.
      CONNECTOR = "y";
      PROC_EVENTS = "y";
    };

    tracing = {
      FTRACE = "y";
      KPROBES = "y";
      FUNCTION_TRACER = "y";
      FTRACE_SYSCALLS = "y";
      SCHED_TRACER = "y";
      STACK_TRACER = "y";
      UPROBE_EVENT = whenOlder "4.11" "y";
      UPROBE_EVENTS = whenAtLeast "4.11" "y";
      BPF_SYSCALL = "y";
      BPF_UNPRIV_DEFAULT_OFF = whenBetween "5.10" "5.16" "y";
      BPF_EVENTS = "y";
      FUNCTION_PROFILER = "y";
      RING_BUFFER_BENCHMARK = "n";
    };

    virtualisation = {
      PARAVIRT = "y";

      HYPERVISOR_GUEST = "y";
      PARAVIRT_SPINLOCKS = "y";

      KVM_ASYNC_PF = "y";
      KVM_COMPAT = whenOlder "4.12" "y";
      KVM_DEVICE_ASSIGNMENT = whenOlder "4.12" "y";
      KVM_GENERIC_DIRTYLOG_READ_PROTECT = "y";
      KVM_GUEST = "y";
      KVM_MMIO = "y";
      KVM_VFIO = "y";
      KSM = "y";
      VIRT_DRIVERS = "y";
      # We need 64 GB (PAE) support for Xen guest support
      HIGHMEM64G = mkIf (!stdenv.is64bit) "y";

      VFIO_PCI_VGA = mkIf stdenv.is64bit "y";

      # VirtualBox guest drivers in the kernel conflict with the ones in the
      # official additions package and prevent the vboxsf "m" from loading,
      # so disable them for now.
      VBOXGUEST = "n";
      DRM_VBOXVIDEO = "n";

      XEN = "y";
      XEN_DOM0 = "y";
      PCI_XEN = "y";
      HVC_XEN = "y";
      HVC_XEN_FRONTEND = "y";
      XEN_SYS_HYPERVISOR = "y";
      SWIOTLB_XEN = "y";
      XEN_BACKEND = "y";
      XEN_BALLOON = "y";
      XEN_BALLOON_MEMORY_HOTPLUG = "y";
      XEN_EFI = "y";
      XEN_HAVE_PVMMU = "y";
      XEN_MCE_LOG = "y";
      XEN_PVH = "y";
      XEN_PVHVM = "y";
      XEN_SAVE_RESTORE = "y";
      XEN_SCRUB_PAGES = whenOlder "4.18" "y";
      XEN_SELFBALLOONING = whenOlder "5.2" "y";
      XEN_STUB = whenOlder "5.12" "y";
      XEN_TMEM = whenOlder "5.12" "y";
    };

    media = {
      MEDIA_DIGITAL_TV_SUPPORT = "y";
      MEDIA_CAMERA_SUPPORT = "y";
      MEDIA_RC_SUPPORT = whenOlder "4.14" "y";
      MEDIA_CONTROLLER = "y";
      MEDIA_PCI_SUPPORT = "y";
      MEDIA_USB_SUPPORT = "y";
      MEDIA_ANALOG_TV_SUPPORT = "y";
      VIDEO_STK1160_COMMON = "m";
      VIDEO_STK1160_AC97 = whenOlder "4.11" "y";
    };

    "9p" = {
      # Enable the 9P cache to speed up NixOS VM tests.
      "9P_FSCACHE" = "y";
      "9P_FS_POSIX_ACL" = "y";
    };

    huge-page = {
      TRANSPARENT_HUGEPAGE = "y";
      TRANSPARENT_HUGEPAGE_ALWAYS = "n";
      TRANSPARENT_HUGEPAGE_MADVISE = "y";
    };

    zram = {
      ZRAM = "m";
      ZSWAP = "y";
      ZBUD = "y";
      ZSMALLOC = "m";
    };

    brcmfmac = {
      # Enable PCIe and USB for the brcmfmac driver
      BRCMFMAC_USB = "y";
      BRCMFMAC_PCIE = "y";
    };

    # Support x2APIC (which requires IRQ remapping)
    x2apic = optionalAttrs (stdenv.hostPlatform.system == "x86_64-linux") {
      X86_X2APIC = "y";
      IRQ_REMAP = "y";
    };

    # Disable various self-test modules that have "n" use in a production system
    tests = {
      # This menu disables all/most of them on >= 4.16
      RUNTIME_TESTING_MENU = "n";
    } // optionalAttrs (versionOlder version "4.16") {
      # For older kernels, painstakingly disable each symbol.
      ARM_KPROBES_TEST = "n";
      ASYNC_RAID6_TEST = "n";
      ATOMIC64_SELFTEST = "n";
      BACKTRACE_SELF_TEST = "n";
      INTERVAL_TREE_TEST = "n";
      PERCPU_TEST = "n";
      RBTREE_TEST = "n";
      TEST_BITMAP = "n";
      TEST_BPF = "n";
      TEST_FIRMWARE = "n";
      TEST_HASH = "n";
      TEST_HEXDUMP = "n";
      TEST_KMOD = "n";
      TEST_KSTRTOX = "n";
      TEST_LIST_SORT = "n";
      TEST_LKM = "n";
      TEST_PARMAN = "n";
      TEST_PRINTF = "n";
      TEST_RHASHTABLE = "n";
      TEST_SORT = "n";
      TEST_STATIC_KEYS = "n";
      TEST_STRING_HELPERS = "n";
      TEST_UDELAY = "n";
      TEST_USER_COPY = "n";
      TEST_UUID = "n";
    } // {
      CRC32_SELFTEST = "n";
      CRYPTO_TEST = "n";
      EFI_TEST = "n";
      GLOB_SELFTEST = "n";
      DRM_DEBUG_MM_SELFTEST = whenOlder "4.18" "n";
      LNET_SELFTEST = whenOlder "4.18" "n";
      LOCK_TORTURE_TEST = "n";
      MTD_TESTS = "n";
      NOTIFIER_ERROR_INJECTION = "n";
      RCU_PERF_TEST = "n";
      RCU_TORTURE_TEST = "n";
      TEST_ASYNC_DRIVER_PROBE = "n";
      WW_MUTEX_SELFTEST = "n";
      XZ_DEC_TEST = "n";
    };

    # Unconditionally enabled, because it is required for CRIU and
    # it provides the kcmp() system call that Mesa depends on.
    criu = optionalAttrs (versionAtLeast version "4.19") {
      CHECKPOINT_RESTORE = "y";
    };

    misc =
      let
        # Use zstd for kernel compression if 64-bit and newer than 5.9, otherwise xz.
        # i686 issues: https://github.com/NixOS/nixpkgs/pull/117961#issuecomment-812106375
        useZstd = stdenv.buildPlatform.is64bit && versionAtLeast version "5.9";
      in
      {
        KERNEL_XZ = mkIf (!useZstd) "y";
        KERNEL_ZSTD = mkIf useZstd "y";

        HID_BATTERY_STRENGTH = "y";
        # enabled by default in x86_64 but not arm64, so we do that here
        HIDRAW = "y";

        HID_ACRUX_FF = "y";
        DRAGONRISE_FF = "y";
        GREENASIA_FF = "y";
        HOLTEK_FF = "y";
        JOYSTICK_PSXPAD_SPI_FF = whenAtLeast "4.14" "y";
        LOGIG940_FF = "y";
        NINTENDO_FF = whenAtLeast "5.16" "y";
        PLAYSTATION_FF = whenAtLeast "5.12" "y";
        SONY_FF = "y";
        SMARTJOYPLUS_FF = "y";
        THRUSTMASTER_FF = "y";
        ZEROPLUS_FF = "y";

        MODULE_COMPRESS = whenOlder "5.13" "y";
        MODULE_COMPRESS_XZ = "y";

        SYSVIPC = "y"; # System-V IPC

        AIO = "y"; # POSIX asynchronous I/O

        UNIX = "y"; # Unix domain sockets.

        MD = "y"; # Device mapper (RAID, LVM, etc.)

        # Enable initrd support.
        BLK_DEV_INITRD = "y";

        PM_TRACE_RTC = "n"; # Disable some expensive (?) features.
        ACCESSIBILITY = "y"; # Accessibility support
        AUXDISPLAY = "y"; # Auxiliary Display support
        DONGLE = whenOlder "4.17" "y"; # Serial dongle support
        HIPPI = "y";
        MTD_COMPLEX_MAPPINGS = "y"; # needed for many devices

        SCSI_LOWLEVEL = "y"; # enable lots of SCSI devices
        SCSI_LOWLEVEL_PCMCIA = "y";
        SCSI_SAS_ATA = "y"; # added to enable detection of hard drive

        SPI = "y"; # needed for many devices
        SPI_MASTER = "y";

        "8139TOO_8129" = "y";
        "8139TOO_PIO" = whenOlder "6.0" "n"; # PIO is slower

        AIC79XX_DEBUG_ENABLE = "n";
        AIC7XXX_DEBUG_ENABLE = "n";
        AIC94XX_DEBUG = "n";

        BLK_DEV_INTEGRITY = "y";

        BLK_SED_OPAL = whenAtLeast "4.14" "y";

        BSD_PROCESS_ACCT_V3 = "y";

        SERIAL_DEV_BUS = whenAtLeast "4.11" "y"; # enables support for serial devices
        SERIAL_DEV_CTRL_TTYPORT = whenAtLeast "4.11" "y"; # enables support for TTY serial devices

        BT_HCIBTUSB_MTK = whenAtLeast "5.3" "y"; # MediaTek protocol support
        BT_HCIUART_QCA = "y"; # Qualcomm Atheros protocol support
        BT_HCIUART_SERDEV = whenAtLeast "4.12" "y"; # required by BT_HCIUART_QCA
        BT_HCIUART = "m"; # required for BT devices with serial port interface (QCA6390)
        BT_HCIUART_BCSP = "y";
        BT_HCIUART_H4 = "y"; # UART (H4) protocol support
        BT_HCIUART_LL = "y";
        BT_RFCOMM_TTY = "y"; # RFCOMM TTY support
        BT_QCA = "m"; # enables QCA6390 bluetooth

        # Removed on 5.17 as it was unused
        # upstream: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=0a4ee518185e902758191d968600399f3bc2be31
        CLEANCACHE = whenOlder "5.17" "y";
        CRASH_DUMP = "n";

        DVB_DYNAMIC_MINORS = "y"; # we use udev

        EFI_STUB = "y"; # EFI bootloader in the bzImage itself
        EFI_GENERIC_STUB_INITRD_CMDLINE_LOADER =
          whenAtLeast "5.8" "y"; # initrd kernel parameter for EFI
        CGROUPS = "y"; # used by systemd
        FHANDLE = "y"; # used by systemd
        SECCOMP = "y"; # used by systemd >= 231
        SECCOMP_FILTER = "y"; # ditto
        POSIX_MQUEUE = "y";
        FRONTSWAP = "y";
        FUSION = "y"; # Fusion MPT device support
        IDE = whenOlder "5.14" "n"; # deprecated IDE support, removed in 5.14
        IDLE_PAGE_TRACKING = "y";
        IRDA_ULTRA = whenOlder "4.17" "y"; # Ultra (connectionless) protocol

        JOYSTICK_IFORCE_232 = whenOlder "5.3" "y"; # I-Force Serial joysticks and wheels
        JOYSTICK_IFORCE_USB = whenOlder "5.3" "y"; # I-Force USB joysticks and wheels
        JOYSTICK_XPAD_FF = "y"; # X-Box gamepad rumble support
        JOYSTICK_XPAD_LEDS = "y"; # LED Support for Xbox360 controller 'BigX' LED

        KEYBOARD_APPLESPI = whenAtLeast "5.3" "m";

        KEXEC_FILE = "y";
        KEXEC_JUMP = "y";

        PARTITION_ADVANCED = "y"; # Needed for LDM_PARTITION
        # Windows Logical Disk Manager (Dynamic Disk) support
        LDM_PARTITION = "y";
        LOGIRUMBLEPAD2_FF = "y"; # Logitech Rumblepad 2 force feedback
        LOGO = "n"; # not needed
        MEDIA_ATTACH = "y";
        MEGARAID_NEWGEN = "y";

        MLX5_CORE_EN = "y";

        NVME_MULTIPATH = whenAtLeast "4.15" "y";

        PSI = whenAtLeast "4.20" "y";

        MOUSE_ELAN_I2C_SMBUS = "y";
        MOUSE_PS2_ELANTECH = "y"; # Elantech PS/2 protocol extension
        MOUSE_PS2_VMMOUSE = "y";
        MTRR_SANITIZER = "y";
        NET_FC = "y"; # Fibre Channel driver support
        # Needed for touchpads to work on some AMD laptops
        PINCTRL_AMD = whenAtLeast "5.19" "y";
        # GPIO on Intel Bay Trail, for some Chromebook internal eMMC disks
        PINCTRL_BAYTRAIL = "y";
        # GPIO for Braswell and Cherryview devices
        # Needs to be built-in to for integrated keyboards to function properly
        PINCTRL_CHERRYVIEW = "y";
        # 8 is default. Modern gpt tables on eMMC may go far beyond 8.
        MMC_BLOCK_MINORS = "32";

        REGULATOR = "y"; # Voltage and Current Regulator Support
        RC_DEVICES = "y"; # Enable IR devices

        RT2800USB_RT53XX = "y";
        RT2800USB_RT55XX = "y";

        SCHED_AUTOGROUP = "y";
        CFS_BANDWIDTH = "y";

        SCSI_LOGGING = "y"; # SCSI logging facility
        SERIAL_8250 = "y"; # 8250/16550 and compatible serial support

        SLAB_FREELIST_HARDENED = whenAtLeast "4.14" "y";
        SLAB_FREELIST_RANDOM = whenAtLeast "4.10" "y";

        SLIP_COMPRESSED = "y"; # CSLIP compressed headers
        SLIP_SMART = "y";

        HWMON = "y";
        THERMAL_HWMON = "y"; # Hardware monitoring support
        NVME_HWMON = whenAtLeast "5.5" "y"; # NVMe drives temperature reporting
        UEVENT_HELPER = "n";

        USERFAULTFD = "y";
        X86_CHECK_BIOS_CORRUPTION = "y";
        X86_MCE = "y";

        RAS = "y"; # Needed for EDAC support

        # Our initrd init uses shebang scripts, so can't be modular.
        BINFMT_SCRIPT = "y";
        # For systemd-binfmt
        BINFMT_MISC = "y";

        # Disable the firmware helper fallback, udev doesn't implement it any more
        FW_LOADER_USER_HELPER_FALLBACK = "n";

        FW_LOADER_COMPRESS = "y";

        HOTPLUG_PCI_ACPI = "y"; # PCI hotplug using ACPI
        HOTPLUG_PCI_PCIE = "y"; # PCI-Expresscard hotplug support

        # Enable AMD's ROCm GPU compute stack
        HSA_AMD = mkIf stdenv.hostPlatform.is64bit (whenAtLeast "4.20" "y");
        ZONE_DEVICE = mkIf stdenv.hostPlatform.is64bit (whenAtLeast "5.3" "y");
        HMM_MIRROR = whenAtLeast "5.3" "y";
        DRM_AMDGPU_USERPTR = whenAtLeast "5.3" "y";

        PREEMPT = "n";
        PREEMPT_VOLUNTARY = "y";

        X86_AMD_PLATFORM_DEVICE = "y";
        X86_PLATFORM_DRIVERS_DELL = whenAtLeast "5.12" "y";

        LIRC = mkMerge [ (whenOlder "4.16" "m") (whenAtLeast "4.17" "y") ];

        SCHED_CORE = whenAtLeast "5.14" "y";

        FSL_MC_UAPI_SUPPORT = mkIf (stdenv.hostPlatform.system == "aarch64-linux") (whenAtLeast "5.12" "y");

        ASHMEM = whenBetween "5.0" "5.18" "y";
        ANDROID = whenBetween "5.0" "5.19" "y";
        ANDROID_BINDER_IPC = whenAtLeast "5.0" "y";
        ANDROID_BINDERFS = whenAtLeast "5.0" "y";
        ANDROID_BINDER_DEVICES = whenAtLeast "5.0" "binder,hwbinder,vndbinder";

        TASKSTATS = "y";
        TASK_DELAY_ACCT = "y";
        TASK_XACCT = "y";
        TASK_IO_ACCOUNTING = "y";

        # Fresh toolchains frequently break -Werror build for minor issues.
        WERROR = whenAtLeast "5.15" "n";
      } // optionalAttrs (stdenv.hostPlatform.system == "x86_64-linux" || stdenv.hostPlatform.system == "aarch64-linux") {
        # Enable CPU/memory hotplug support
        # Allows you to dynamically add & remove CPUs/memory to a VM client running NixOS without requiring a reboot
        ACPI_HOTPLUG_CPU = "y";
        ACPI_HOTPLUG_MEMORY = "y";
        MEMORY_HOTPLUG = "y";
        MEMORY_HOTREMOVE = "y";
        HOTPLUG_CPU = "y";
        MIGRATION = "y";
        SPARSEMEM = "y";

        # Bump the maximum number of CPUs to support systems like EC2 x1.*
        # instances and Xeon Phi.
        # FIXME: 
        # NR_CPUS = "384";
      } // optionalAttrs (stdenv.hostPlatform.system == "armv7l-linux" || stdenv.hostPlatform.system == "aarch64-linux") {
        # Enables support for the Allwinner Display Engine 2.0
        SUN8I_DE2_CCU = whenAtLeast "4.13" "y";

        # See comments on https://github.com/NixOS/nixpkgs/commit/9b67ea9106102d882f53d62890468071900b9647
        CRYPTO_AEGIS128_SIMD = whenAtLeast "5.4" "n";

        # Distros should configure the default as a kernel option.
        # We previously defined it on the kernel command line as cma=
        # The kernel command line will override a platform-specific configuration from its device tree.
        # https://github.com/torvalds/linux/blob/856deb866d16e29bd65952e0289066f6078af773/kernel/dma/contiguous.c#L35-L44
        CMA_SIZE_MBYTES = "32";

        # Many ARM SBCs hand off a pre-configured framebuffer.
        # This always can can be replaced by the actual native driver.
        # Keeping it a built-in ensures it will be used if possible.
        FB_SIMPLE = "y";

      } // optionalAttrs (versionAtLeast version "5.4" && (stdenv.hostPlatform.system == "x86_64-linux" || stdenv.hostPlatform.system == "aarch64-linux")) {
        # Required for various hardware features on Chrome OS devices
        CHROME_PLATFORMS = "y";
        CHROMEOS_TBMC = "m";

        CROS_EC = "m";

        CROS_EC_I2C = "m";
        CROS_EC_SPI = "m";
        CROS_EC_LPC = "m";
        CROS_EC_ISHTP = "m";

        CROS_KBD_LED_BACKLIGHT = "m";
      } // optionalAttrs (versionAtLeast version "5.4" && stdenv.hostPlatform.system == "x86_64-linux") {
        CHROMEOS_LAPTOP = "m";
        CHROMEOS_PSTORE = "m";
      };
  };
in
flattenKConf options
