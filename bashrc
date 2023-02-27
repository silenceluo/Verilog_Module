export VERDI_HOME=/apps/synopsys/verdi/Q-2020.03-1/
export VCS_HOME=/apps/synopsys/vcs/Q-2020.03-1/
export UVM_HOME=/apps/synopsys/vcs/Q-2020.03-1/etc/uvm-1.2

export PATH=$PATH:$VERDI_HOME/bin
export PATH=$PATH:$VCS_HOME/bin

export LD_LIBRARY_PATH=$VERDI_HOME/share/PLI/VCS/linux64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/apps/synopsys/vcs/Q-2020.03-1/linux64/lib/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/shared/ip_tools/cryptolibs/
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/apps/anaconda3/lib/
export DESIGNWARE_HOME=/data/shared/ace/VC_VIP_S-2021.06/
export SLI_LOCAL_MODE=1


export NOVAS_HOME=/apps/synopsys/verdi/Q-2020.03-1/
export NOVAS_PLI=${NOVAS_HOME}/share/PLI/VCS/LINUX64
export LD_LIBRARY_PATH=$NOVAS_PLI
export NOVAS="${NOVAS_HOME}/share/PLI/VCS/LINUX64"

# export SNPSLMD_LICENSE_FILE=27020@dt-license1.aka.amazon.com
# export SNPSLMD_LICENSE_FILE=27050@dt-license1.aka.amazon.com:27020@dt-license1.aka.amazon.com

SNPSLMD_LICENSE_FILE=$SNPSLMD_LICENSE_FILE:27050@dt-license1.aka.amazon.com
export SNPSLMD_LICENSE_FILE
SNPSLMD_LICENSE_FILE=$SNPSLMD_LICENSE_FILE:27020@dt-license1.aka.amazon.com
export SNPSLMD_LICENSE_FILE

##### BEGIN Power Artist CUSTOMIZATION #####
export POWERARTIST_ROOT=/apps/ansys_inc/PowerArtist/2019R2.5p2
PATH=$PATH:$POWERARTIST_ROOT/bin
export LM_LICENSE_FILE=27043@dt-license1.aka.amazon.com:27050@dt-license1.aka.amazon.com:27020@dt-license1.aka.amazon.com
##### END PowerArtist CUSTOMIZATION #####

export JENKINS_WORKSPACE=/data/shared/jenkins/ace/.jenkins/workspace


# DC Synthesis
export DC_HOME=/apps/synopsys/syn/S-2021.06-SP2/
export PATH=$DC_HOME/bin:$PATH

# Spyglass
export SPYGLASS_HOME=/apps/synopsys/spyglass/T-2022.06/SPYGLASS_HOME/
export PATH=$SPYGLASS_HOME/bin:$PATH

export PATH=$PATH:/data/home/tafzal/opt/bin
export PATH=$PATH:/apps/gtkwave/3.3.93/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/apps/gtkwave/tcl/lib:/apps/gtkwave/tk/lib

# wait for DW license for VIP
export DW_WAIT_LICENSE=1
export SNPSLMD_QUEUE=TRUE




# Questa
# export LM_LICENSE_FILE=1717@dt-license1.aka.amazon.com
# export QUESTA_HOME=/apps/mentor/questasim_2021.1_1/questasim
# export PATH=$PATH:$QUESTA_HOME/bin

export RISCV=/data/shared/ace/luopl/opt

export PATH=$PATH:/data/home/tafzal/opt/bin
export PATH=$PATH:/apps/gtkwave/3.3.93/bin

# DC
#   export PATH=$PATH:/apps/synopsys/syn/N-2017.09-SP5/linux64/syn/bin
#   export PATH=$PATH:/apps/synopsys/syn/Q-2019.12/linux64/syn/bin
export PATH=$PATH:/apps/synopsys/syn/R-2020.09-SP1/linux64/syn/bin

# Python
export PATH=~/.local/bin/:$PATH

# gitk
alias gitk='/data/home/jcwright/install/bin/gitk'

#export SPYGLASS_HOME=/apps/synopsys/spyglass/SPYGLASS2018.09-SP1/SPYGLASS_HOME/
export SPYGLASS_HOME=/apps/synopsys/spyglass/T-2022.06/SPYGLASS_HOME

export PATH=$PATH:$SPYGLASS_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/apps/gtkwave/tcl/lib:/apps/gtkwave/tk/lib

alias l='ls'
alias ll='ls -altr'
alias le='less'
alias python='python3'
alias lmstat='/apps/tools/scripts/lmutil lmstat -a -c 27020@dt-license1.aka.amazon.com:27050@dt-license1.aka.amazon.com'
alias tkdiff='/data/shared/ip_tools/tkdiff-4-3-5/tkdiff'
alias cmake='/data/shared/ip_tools/cmake-3.14.4/bin/cmake'
alias vs='/apps/vscode/latest/code'

alias gs='git status'
alias gu='git remote update'
alias gp='git pull'

alias bfg='java -jar bfg.jar '

alias checklic='/apps/tools/scripts/lmutil lmstat -a -c 27020@dt-license1.aka.amazon.com'
alias checkq='qstat | grep synopsysnow > q.log'
export PATH=$PATH:/apps/vscode/latest/bin

export VCS_LIC_EXPIRE_WARNING=0

#   Gedit   
gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
gsettings set org.gnome.gedit.preferences.editor tabs-size 4
gsettings set org.gnome.gedit.preferences.editor auto-indent true
gsettings set org.gnome.gedit.preferences.editor auto-save true
gsettings set org.gnome.gedit.preferences.editor bracket-matching true
gsettings set org.gnome.gedit.preferences.editor highlight-current-line true
gsettings set org.gnome.gedit.preferences.editor insert-spaces true
gsettings set org.gnome.gedit.preferences.editor search-highlighting true
gsettings set org.gnome.gedit.preferences.editor syntax-highlighting true



