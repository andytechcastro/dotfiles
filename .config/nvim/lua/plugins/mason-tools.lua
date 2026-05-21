-- Simple Mason configuration without auto-install
return {
  "williamboman/mason.nvim",
  lazy = false,
  opts = {
    ui = {
      check_outdated_packages_on_open = true,
      border = "none",
      width = 0.8,
      height = 0.9,
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  }
}
