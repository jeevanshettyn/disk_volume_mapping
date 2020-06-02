#!/bin/sh

#####################################################################################################################################
#!/bin/sh

#####################################################################################################################################
## SCRIPT NAME: disk_volume_mapping.sh                                                                                             ##
## PURPOSE    : To find the mapping between EBS Volume -> OS Device -> ASM Disk                                                    ##
## USAGE      : disk_volume_mapping.sh                                                                                             ##
##                                                                                                                                 ##
## SCRIPT HISTORY:                                                                                                                 ##
## 05/12/2020  Jeevan Shetty        Initial Copy                                                                                   ##
##                                                                                                                                 ##
#####################################################################################################################################

SCRIPT=$0
v_log='/tmp/disk_volume_mapping.log'
v_asm_disk_loc='/dev/oracleasm/disks'
v_region=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c 2- | rev`

echo "`date` : Script - $SCRIPT Started" >$v_log

export ORACLE_SID="+ASM"
export ORAENV_ASK=NO
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

. /usr/local/bin/oraenv >/dev/null

#
# Setting 64 bit libraries used by aws/python
#
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH


#
# For every disk identified in above query, identify device name, EBS volume id and current disk size. These EBS volumes will be resized by increments defined in variable - v_vol_size_incr
#
ls $v_asm_disk_loc | grep -v "^ *$" | while read v_disk_name
do

    #
    # The major & minor# of asm disk under /dev/oracleasm/disks and disks under /dev/ match. This is used to identify the device name.
    # The device name will be used to identify the EBS volume id and current size, which will be eventually resized to v_new_vol_size.
    #
    v_major_minor_num=`ls -l $v_asm_disk_loc/$v_disk_name | tr -s ' ' | awk '{print $5,$6}'`

    #
    # Below we find the sub-partition name of the device, EBS volume id and its size
    #
    v_device=`ls -l /dev/nvme* | tr -s ' ' | grep -w "$v_major_minor_num" | cut -f 10 -d ' '`
    v_vol_id=`sudo nvme id-ctrl -v "$v_device" | grep "^sn" | cut -f 2 -d ':' | sed 's/ vol/vol-/'`
    v_vol_size=`aws ec2 describe-volumes --region $v_region --volume-id $v_vol_id --query "Volumes[0].{SIZE:Size}" | grep "SIZE" | tr -s ' ' | cut -f 3 -d ' '`

    echo "`date` : Disk = `hostname`_$v_disk_name, Device Name = $v_device, Volume = $v_vol_id, Current Size = $v_vol_size"


done


echo "`date` : Script - $SCRIPT Completed" >>$v_log
echo "`date` : " >>$v_log
echo "`date` : " >>$v_log
