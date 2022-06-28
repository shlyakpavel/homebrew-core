class Reaver < Formula
  desc "Implements brute force attack to recover WPA/WPA2 passkeys"
  homepage "https://github.com/t6x/reaver-wps-fork-t6x"
  url "https://github.com/t6x/reaver-wps-fork-t6x/releases/download/v1.6.6/reaver-1.6.6.tar.xz"
  sha256 "e329a0da0b6dd888916046535ff86a6aa144644561937954e560bb1810ab6702"
  license "GPL-2.0-or-later"

  bottle do
    sha256 arm64_monterey: "c5aebd64ad2c3055146fea9e91914d689914d1aab4e945f354264183a190bd97"
    sha256 arm64_big_sur:  "c4ba873b94ad8d7f968474660417e7af8ea607f9b42d3971533f84377a56a3d2"
    sha256 monterey:       "2c8d6a61a5f75a853946a9f982c81b7d1c37f5ddd9fafaf61d862bb2dfb24be3"
    sha256 big_sur:        "0cd13169a7c0f7603fab7ec7ac55e8896ffd5518c4e790a59183e894291a5cab"
    sha256 catalina:       "73539f97836b5df80e030e429eb7f209dec3067c14b1bfd6753bcf7796c1f541"
    sha256 mojave:         "386ed8ae2562ae032f0d622d52d7302be2e99bbe671f1ca5ba3acb88b86f6417"
    sha256 high_sierra:    "c2c6d45abc45f5639b74da0bdb294a5ee83548f548642f6b61d764d05801352e"
    sha256 sierra:         "e7fc0f43b7a306d5fe2baaf4b41e9ce445db12e2e74d41904b3de5d2c372741d"
    sha256 el_capitan:     "d9adddf27928b284492cc87b565d2748490c1017b0b463bc15223c935f63bb6c"
    sha256 x86_64_linux:   "1a1e6c2edefa97af1a4295d859695c6dbc055a47676f9ec845916362bcc884f6"
  end

  depends_on "pixiewps"

  uses_from_macos "libpcap"
  uses_from_macos "sqlite"

  def install
    # reported upstream in https://github.com/t6x/reaver-wps-fork-t6x/issues/195
    man1.install "docs/reaver.1"
    prefix.install_metafiles "docs"
    cd "src"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    bin.mkpath
    system "make", "install"
  end
end
