#!/usr/bin/env bash
akq status | grep akd1500
bash $HOME/akida_test/run_image.sh ubuntu24.04-cpu-x86 full
bash $HOME/akida_test/run_image.sh ubuntu22.04-cpu-x86 part
echo BATCHDONE
