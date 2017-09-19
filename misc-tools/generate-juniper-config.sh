#!/bin/sh

# ranges per cloud:
#   1100-1103 (cloud01)
#   1110-1113 (cloud02)
#   1120-1123 (cloud03)
#   1130-1133 (cloud04)
#   1140-1143 (cloud05)
#   1150-1153 (cloud06)
#   1160-1163 (cloud07)
#   1170-1173 (cloud08)
#   1180-1183 (cloud09)
#   1190-1193 (cloud10)
#   1200-1203 (cloud11)
#   1210-1213 (cloud12)
#   1220-1223 (cloud13)
#   1230-1233 (cloud14)
#   1240-1243 (cloud15)
#   1250-1253 (cloud16)
#   1260-1263 (cloud17)
#   1270-1273 (cloud18)
#   1280-1283 (cloud19)
#   1290-1293 (cloud20)
#   1300-1303 (cloud21)
#   1310-1313 (cloud22)
#   1320-1323 (cloud23)
#   1330-1333 (cloud24)

# There are two distribution switches serving connections to TORs
#   dist1 - 10.12.252.242
#   dist2 - 10.12.252.241

# Add the following configurations to the dist switches:

cloudname=$1
cloudnumber=$(echo $cloudname | sed 's/cloud//')

if expr $cloudnumber + 0 1>/dev/null 2>&1 ; then
  :
else
  echo cloudnumber not valid: $cloudnumber
  exit 1
fi

offset=$(expr $cloudnumber \* 10)
rangestart=$(expr 1090 + $offset)
rangeend=$(expr 1090 + $offset + 3)
range=$rangestart-$rangeend

echo "Add the following configs to the two dist switches: "
echo ""

echo 'set groups ACCESS_TRUNK interfaces <*> unit 0 family ethernet-switching vlan members '$range
for i in $(seq $rangestart $rangeend) ; do
  echo "set protocols igmp-snooping vlan vlan$i"
  echo "set protocols vstp vlan $i bridge-priority 4k"
  echo "set vlans vlan$i description vlan$i"
  echo "set vlans vlan$i vlan-id $i"
done

echo "============"

echo "Add the following configs to the TOR switches: "
echo ""

for i in $(seq $rangestart $rangeend) ; do
  for section in "flexible-vlan-tagging" "native-vlan-id $i" "mtu 9216" "encapsulation extended-vlan-bridge" "unit 0 vlan-id-list 1-4000" "unit 0 input-vlan-map push" "unit 0 output-vlan-map pop" ; do
    echo "set groups QinQ_vl$i interfaces <*> $section"
  done
  echo "set interfaces ae1 unit $i vlan-id $i"
  echo "set protocols vstp vlan $i bridge-priority 24k"
  echo "set vlans vlan$i description vlan$i"
  echo "set vlans vlan$i interface ae1.$i"

done
