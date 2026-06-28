# This cask is auto-updated by the update-cask workflow.
# Do not edit the version or sha256 lines manually.
cask "qview" do
  version "7.1"
  sha256 "fa34d0e54601b8557f4e879527b9bb1e728ace5c7c1c69cf126700ca4d0b5817"

  url "https://github.com/engels74/homebrew-qview/releases/download/latest/qView-#{version}.dmg"
  name "qView"
  desc "Practical and minimal image viewer"
  homepage "https://github.com/jurplel/qView/"

  depends_on macos: :monterey

  app "qView.app"

  postflight do
    app_path = File.join(appdir, "qView.app")

    ohai "Removing quarantine attribute from #{app_path}"
    system_command "/usr/bin/xattr",
                   args:         ["-r", "-d", "com.apple.quarantine", app_path],
                   sudo:         false,
                   must_succeed: false
  end

  zap trash: [
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.interversehq.qview.sfl*",
    "~/Library/Preferences/com.interversehq.qView.plist",
    "~/Library/Preferences/com.qview.qView.plist",
    "~/Library/Saved Application State/com.interversehq.qView.savedState",
  ]
end
