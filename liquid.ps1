
#######################################
# LIQUID PROMPT DEFAULT TEMPLATE FILE #
#######################################

# Available features:
# LP_BATT battery
# LP_LOAD load
# LP_JOBS screen sessions/running jobs/suspended jobs
# LP_USER user
# LP_HOST hostname
# LP_PERM a colon ":"
# LP_PWD current working directory
# LP_PROXY HTTP proxy
# LP_VCS the content of the current repository
# LP_ERR last error code
# LP_MARK prompt mark
# LP_TIME current time
# LP_PS1_PREFIX user-defined general-purpose prefix (default set a generic prompt as the window title)

# Remember that most features come with their corresponding colors,
# see the README.

get_sf_prefix()
{
	if [ -n "${SF_PREFIX}" ] ; then
    	prefix=${SF_PREFIX#/var/tmp/mab/}
    	SF_PREFIX_PROMPT="(sfp=${prefix})"
	else
    	SF_PREFIX_PROMPT=
	fi
	#echo -n "${SF_PREFIX_PROMPT}"
}
#LP_PS1_PREFIX=$(get_sf_prefix)
#get_sf_prefix
# add time, jobs, load and battery
LP_PS1="${LP_PS1_PREFIX}${LP_LOAD}${LP_JOBS}"
# add user, host and permissions colon
LP_PS1="${LP_PS1}[${LP_USER}${LP_HOST}${LP_PERM}"

# if not root
if [[ "$EUID" -ne "0" ]]
then
    # path in foreground color
    LP_PS1="${LP_PS1}${LP_PWD}]${LP_VENV}${LP_PROXY}"
    # add VCS infos
    LP_PS1="${LP_PS1}${LP_VCS}"
else
    # path in yellow
    LP_PS1="${LP_PS1}${LP_PWD}]${LP_VENV}${LP_PROXY}"
    # do not add VCS infos unless told otherwise (LP_ENABLE_VCS_ROOT)
    [[ "$LP_ENABLE_VCS_ROOT" = "1" ]] && LP_PS1="${LP_PS1}${LP_VCS}"
fi

# add return code and prompt mark
LP_PS1="${LP_PS1}${LP_ERR}${LP_MARK}"

# vim: set et sts=4 sw=4 tw=120 ft=sh:
