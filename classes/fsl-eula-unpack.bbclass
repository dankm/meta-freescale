# fsl-eula-unpack.bbclass provides the mechanism used for unpacking
# the .bin file downloaded by HTTP and handle the EULA acceptance.
#
# To use it, the 'fsl-eula' parameter needs to be added to the
# SRC_URI entry, e.g:
#
#  SRC_URI = "${FSL_MIRROR}/firmware-imx-${PV};fsl-eula=true"

LIC_FILES_CHKSUM_append = " file://${FSL_EULA_FILE};md5=ab61cab9599935bfe9f700405ef00f28"

LIC_FILES_CHKSUM[vardepsexclude] += "FSL_EULA_FILE"

python fsl_bin_do_unpack() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    localdata = bb.data.createCopy(d)
    bb.data.update_data(localdata)

    rootdir = localdata.getVar('WORKDIR', True)
    fetcher = bb.fetch2.Fetch(src_uri, localdata)

    for url in fetcher.ud.values():
        # Skip this fetcher if it's not under EULA or if the fetcher type is not supported
        if not url.parm.get('fsl-eula', False) or url.type not in ['http', 'https', 'ftp', 'file']:
            continue
        # If download has failed, do nothing
        if not os.path.exists(url.localpath):
            bb.debug(1, "Exiting as '%s' cannot be found" % url.basename)
            return
        bb.note("Handling file '%s' as a Freescale EULA-licensed archive." % url.basename)
        cmd = "sh %s --auto-accept --force" % (url.localpath)
        bb.fetch2.runfetchcmd(cmd, d, quiet=True, workdir=rootdir)
}

python do_unpack() {
    eula = d.getVar('ACCEPT_FSL_EULA')
    eula_file = d.getVar('FSL_EULA_FILE')
    pkg = d.getVar('PN')
    if eula == None:
        bb.fatal("To use '%s' you need to accept the Freescale EULA at '%s'. "
                 "Please read it and in case you accept it, write: "
                 "ACCEPT_FSL_EULA = \"1\" in your local.conf." % (pkg, eula_file))
    elif eula == '0':
        bb.fatal("To use '%s' you need to accept the Freescale EULA." % pkg)
    else:
        bb.note("Freescale EULA has been accepted for '%s'" % pkg)

    # The binary unpack needs to be done first so 'S' is valid
    bb.build.exec_func('fsl_bin_do_unpack', d)

    try:
        bb.build.exec_func('base_do_unpack', d)
    except:
        raise
}

do_unpack[vardepsexclude] += "FSL_EULA_FILE"
