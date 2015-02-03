#!/bin/bash

source ~/.bashrc

ssh -f -N tunnel
setup_mux indus.englab.sourcefire.com
setup_mux pecan.englab.sourcefire.com
setup_mux scm.esn.sourcefire.com
setup_mux ajax.englab.sourcefire.com
mount-sshfs-scm pecan:transfer ~/transfer
