Below are some notes on how to resize the disks when a new drive is added to
our dedicated hosts:

```
fdisk /dev/nvme3n1
# create gpt partition table and new RAID 5 (label 42) partition using the CLI 
mdadm --manage /dev/md3 --add /dev/nvme3n1p1
cat /proc/mdstat
# Take note of the volume count (4) and validate that nvme3n1p1 is marked as spare ("S")
mdadm --grow --raid-devices=4 /dev/md3
```

```
# resize2fs /dev/md3
# df -h | grep md3
/dev/md3        2.6T  1.2T  1.3T  48% /
```
