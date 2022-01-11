final: _: {
  mkKernelConfig = final.callPackage ./kernel/kconfig.nix { };

  testConfig = final.mkKernelConfig
    {
      inherit (final.linux_latest) pname version patches makeFlags;
      src = /home/bemeurer/tmp/kernel/linux-5.16;
    }
    {
      CRASH_DUMP = "n";
      DEBUG_DEVRES = "n";
      DEBUG_INFO = "y";
      DEBUG_KERNEL = "y";
      # DEBUG_STACK_USAGE = "n";
      # DETECT_HUNG_TASK = "y";
      # DYNAMIC_DEBUG = "y";
      # RCU_TORTURE_TEST = "n";
      # SCHEDSTATS = "n";
      # SCHED_DEBUG = "y";
      # SUNRPC_DEBUG = "y";
    };
}
