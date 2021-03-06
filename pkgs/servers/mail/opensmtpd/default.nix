{ lib, stdenv, fetchurl, autoconf, automake, libtool, bison
, libasr, libevent, zlib, libressl, db, pam, nixosTests
}:

stdenv.mkDerivation rec {
  pname = "opensmtpd";
  version = "6.7.1p1";

  nativeBuildInputs = [ autoconf automake libtool bison ];
  buildInputs = [ libasr libevent zlib libressl db pam ];

  src = fetchurl {
    url = "https://www.opensmtpd.org/archives/${pname}-${version}.tar.gz";
    sha256 = "1jh8vxfajm1mvp1v5yh6llrhjzv0n9fgab88mlwllwqynhcfjy3l";
  };

  patches = [
    ./proc_path.diff # TODO: upstream to OpenSMTPD, see https://github.com/NixOS/nixpkgs/issues/54045
  ];

  # See https://github.com/OpenSMTPD/OpenSMTPD/issues/885 for the `sh bootstrap`
  # requirement
  postPatch = ''
    substituteInPlace mk/smtpctl/Makefile.am --replace "chgrp" "true"
    substituteInPlace mk/smtpctl/Makefile.am --replace "chmod 2555" "chmod 0555"
    sh bootstrap
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-mantype=doc"
    "--with-auth-pam"
    "--without-auth-bsdauth"
    "--with-path-socket=/run"
    "--with-user-smtpd=smtpd"
    "--with-user-queue=smtpq"
    "--with-group-queue=smtpq"
    "--with-path-CAfile=/etc/ssl/certs/ca-certificates.crt"
    "--with-libevent=${libevent.dev}"
    "--with-table-db"
  ];

  # See https://github.com/OpenSMTPD/OpenSMTPD/pull/884
  makeFlags = [ "CFLAGS=-ffunction-sections" "LDFLAGS=-Wl,--gc-sections" ];

  installFlags = [
    "sysconfdir=\${out}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  meta = with lib; {
    homepage = "https://www.opensmtpd.org/";
    description = ''
      A free implementation of the server-side SMTP protocol as defined by
      RFC 5321, with some additional standard extensions
    '';
    license = licenses.isc;
    platforms = platforms.linux;
    maintainers = with maintainers; [ obadz ekleog ];
  };
  passthru.tests = {
    basic-functionality-and-dovecot-interaction = nixosTests.opensmtpd;
  };
}
