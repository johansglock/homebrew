class HpnSsh < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "https://www.psc.edu/index.php/hpn-ssh"

  url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.9p1.tar.gz"
  mirror "https://mirror.vdms.io/pub/OpenBSD/OpenSSH/portable/openssh-7.9p1.tar.gz"
  version "7.9p1"
  sha256 "6b4b3ba2253d84ed3771c8050728d597c91cfce898713beb7b64a305b6f11aad"

  conflicts_with 'openssh'

  # Please don't resubmit the keychain patch option. It will never be accepted.
  # https://github.com/Homebrew/homebrew-dupes/pull/482#issuecomment-118994372

  depends_on "pkg-config" => :build
  depends_on "ldns"
  depends_on "openssl"

  # Both these patches are applied by Apple.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/1860b0a74/openssh/patch-sandbox-darwin.c-apple-sandbox-named-external.diff"
    sha256 "d886b98f99fd27e3157b02b5b57f3fb49f43fd33806195970d4567f12be66e71"
  end

  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2/openssh/patch-sshd.c-apple-sandbox-named-external.diff"
    sha256 "3505c58bf1e584c8af92d916fe5f3f1899a6b15cc64a00ddece1dc0874b2f78f"
  end

  # Patch enabling High Performance SSH (hpn-ssh)
  patch do
    url 'https://superb-dca2.dl.sourceforge.net/project/hpnssh/HPN-SSH%2014v16%207.8p1/openssh-7_8_P1-hpn-14.16.diff'
    sha256 "7f57dae4390dd9bdb581903b2442a685eaae0443ddc16d449c685e1b0984a303"
  end

  def install
    ENV.append "CPPFLAGS", "-D__APPLE_SANDBOX_NAMED_EXTERNAL__"

    # Ensure sandbox profile prefix is correct.
    # We introduce this issue with patching, it's not an upstream bug.
    inreplace "sandbox-darwin.c", "@PREFIX@/share/openssh", etc/"ssh"

    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
      --with-ldns
      --with-libedit
      --with-kerberos5
      --with-pam
      --with-ssl-dir=#{Formula["openssl"].opt_prefix}
    ]

    system "./configure", *args
    system "make"
    ENV.deparallelize
    system "make", "install"

    # This was removed by upstream with very little announcement and has
    # potential to break scripts, so recreate it for now.
    # Debian have done the same thing.
    bin.install_symlink bin/"ssh" => "slogin"
  end

  test do
    assert_match "OpenSSH_", shell_output("#{bin}/ssh -V 2>&1")
  end
end
