class Git < Formula
  desc "Distributed revision control system"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.37.1.tar.xz"
  sha256 "c8162c6b8b8f1c5db706ab01b4ee29e31061182135dc27c4860224aaec1b3500"
  license "GPL-2.0-only"
  head "https://github.com/git/git.git", branch: "master"

  livecheck do
    url "https://www.kernel.org/pub/software/scm/git/"
    regex(/href=.*?git[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_monterey: "e426127757c3a18289222a1d4a288fa7d2179db12185a83919fb654d7fb95784"
    sha256 arm64_big_sur:  "d6097643b9d825543b3b32efd3f9dd2935031b95ff798bbd2b390b55e76c21b7"
    sha256 monterey:       "81368cd1e77f3681fc41e6d1a1b69d3a32d8738f1d48975d8be6a81525691334"
    sha256 big_sur:        "e09e33dd11f26f7420ea67258714dcc7f237afbe6385b2098945b369cca48b8e"
    sha256 catalina:       "c3e12004f906fe6b77efcd2cd14b96d035d74bd48286b1792edfa6b53c26054a"
    sha256 x86_64_linux:   "e0ac22cee893ba9aa68f0e7ebfc547351c24ee0bb6df091e21a37826109b13ac"
  end

  depends_on "gettext"
  depends_on "pcre2"

  uses_from_macos "curl", since: :catalina # macOS < 10.15.6 has broken cert path logic
  uses_from_macos "expat"
  uses_from_macos "zlib", since: :high_sierra

  on_linux do
    depends_on "linux-headers@4.4"
    depends_on "openssl@1.1" # Uses CommonCrypto on macOS
  end

  resource "html" do
    url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-htmldocs-2.37.1.tar.xz"
    sha256 "57c81d42d66880d3b3859e22d0f95c054389a97610f7d08d1e9e39e35771ad10"
  end

  resource "man" do
    url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-manpages-2.37.1.tar.xz"
    sha256 "4dcece78fcb9c585f362d2607b05189afb6c8b4e47a21dfdccb5fefd27fa1e25"
  end

  resource "Net::SMTP::SSL" do
    url "https://cpan.metacpan.org/authors/id/R/RJ/RJBS/Net-SMTP-SSL-1.04.tar.gz"
    sha256 "7b29c45add19d3d5084b751f7ba89a8e40479a446ce21cfd9cc741e558332a00"
  end

  def install
    # If these things are installed, tell Git build system not to use them
    ENV["NO_FINK"] = "1"
    ENV["NO_DARWIN_PORTS"] = "1"
    ENV["PYTHON_PATH"] = which("python")
    ENV["PERL_PATH"] = which("perl")
    ENV["USE_LIBPCRE2"] = "1"
    ENV["INSTALL_SYMLINKS"] = "1"
    ENV["LIBPCREDIR"] = Formula["pcre2"].opt_prefix
    ENV["V"] = "1" # build verbosely

    perl_version = Utils.safe_popen_read("perl", "--version")[/v(\d+\.\d+)(?:\.\d+)?/, 1]

    if OS.mac?
      ENV["PERLLIB_EXTRA"] = %W[
        #{MacOS.active_developer_dir}
        /Library/Developer/CommandLineTools
        /Applications/Xcode.app/Contents/Developer
      ].uniq.map do |p|
        "#{p}/Library/Perl/#{perl_version}/darwin-thread-multi-2level"
      end.join(":")
    end

    # The git-gui and gitk tools are installed by a separate formula (git-gui)
    # to avoid a dependency on tcl-tk and to avoid using the broken system
    # tcl-tk (see https://github.com/Homebrew/homebrew-core/issues/36390)
    # This is done by setting the NO_TCLTK make variable.
    args = %W[
      prefix=#{prefix}
      sysconfdir=#{etc}
      CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags}
      LDFLAGS=#{ENV.ldflags}
      NO_TCLTK=1
    ]

    args += if OS.mac?
      %w[NO_OPENSSL=1 APPLE_COMMON_CRYPTO=1]
    else
      openssl_prefix = Formula["openssl@1.1"].opt_prefix

      %W[NO_APPLE_COMMON_CRYPTO=1 OPENSSLDIR=#{openssl_prefix}]
    end

    system "make", "install", *args

    git_core = libexec/"git-core"
    rm git_core/"git-svn"

    # Install the macOS keychain credential helper
    if OS.mac?
      cd "contrib/credential/osxkeychain" do
        system "make", "CC=#{ENV.cc}",
                       "CFLAGS=#{ENV.cflags}",
                       "LDFLAGS=#{ENV.ldflags}"
        git_core.install "git-credential-osxkeychain"
        system "make", "clean"
      end
    end

    # Generate diff-highlight perl script executable
    cd "contrib/diff-highlight" do
      system "make"
    end

    # Install the netrc credential helper
    cd "contrib/credential/netrc" do
      system "make", "test"
      git_core.install "git-credential-netrc"
    end

    # Install git-subtree
    cd "contrib/subtree" do
      system "make", "CC=#{ENV.cc}",
                     "CFLAGS=#{ENV.cflags}",
                     "LDFLAGS=#{ENV.ldflags}"
      git_core.install "git-subtree"
    end

    # install the completion script first because it is inside "contrib"
    bash_completion.install "contrib/completion/git-completion.bash"
    bash_completion.install "contrib/completion/git-prompt.sh"
    zsh_completion.install "contrib/completion/git-completion.zsh" => "_git"
    cp "#{bash_completion}/git-completion.bash", zsh_completion

    (share/"git-core").install "contrib"

    # We could build the manpages ourselves, but the build process depends
    # on many other packages, and is somewhat crazy, this way is easier.
    man.install resource("man")
    (share/"doc/git-doc").install resource("html")

    # Make html docs world-readable
    chmod 0644, Dir["#{share}/doc/git-doc/**/*.{html,txt}"]
    chmod 0755, Dir["#{share}/doc/git-doc/{RelNotes,howto,technical}"]

    # git-send-email needs Net::SMTP::SSL or Net::SMTP >= 2.34
    resource("Net::SMTP::SSL").stage do
      (share/"perl5").install "lib/Net"
    end

    # This is only created when building against system Perl, but it isn't
    # purged by Homebrew's post-install cleaner because that doesn't check
    # "Library" directories. It is however pointless to keep around as it
    # only contains the perllocal.pod installation file.
    rm_rf prefix/"Library/Perl"

    # Set the macOS keychain credential helper by default
    # (as Apple's CLT's git also does this).
    if OS.mac?
      (buildpath/"gitconfig").write <<~EOS
        [credential]
        \thelper = osxkeychain
      EOS
      etc.install "gitconfig"
    end
  end

  def caveats
    <<~EOS
      The Tcl/Tk GUIs (e.g. gitk, git-gui) are now in the `git-gui` formula.
      Subversion interoperability (git-svn) is now in the `git-svn` formula.
    EOS
  end

  test do
    system bin/"git", "init"
    %w[haunted house].each { |f| touch testpath/f }
    system bin/"git", "add", "haunted", "house"
    system bin/"git", "config", "user.name", "'A U Thor'"
    system bin/"git", "config", "user.email", "author@example.com"
    system bin/"git", "commit", "-a", "-m", "Initial Commit"
    assert_equal "haunted\nhouse", shell_output("#{bin}/git ls-files").strip

    # Check Net::SMTP or Net::SMTP::SSL works for git-send-email
    if OS.mac?
      %w[foo bar].each { |f| touch testpath/f }
      system bin/"git", "add", "foo", "bar"
      system bin/"git", "commit", "-a", "-m", "Second Commit"
      assert_match "Authentication Required", pipe_output(
        "#{bin}/git send-email --from=test@example.com --to=dev@null.com " \
        "--smtp-server=smtp.gmail.com --smtp-server-port=587 " \
        "--smtp-encryption=tls --confirm=never HEAD^ 2>&1",
      )
    end
  end
end
