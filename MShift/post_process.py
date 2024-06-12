## MeanShift poorly labels clusters (assigns the same label for 2 different MBFFs), so there can be some conflicts.
## This script places all the FFs with the same MBFF center into a uniquely labeled MBFF.
## Then, each MBFF is split into multiple MBFFs to satisfy the max-capacity constraint.

seen = {}
cnt = 0
next_ind = 0
output_lines = []
with open("output.txt") as fin:
  for line in fin.readlines():
    if (cnt > 1):
      name, x, y, label = line.split()
      cur_key = tuple([x, y, label])
      if cur_key not in seen:
        seen[cur_key] = [name]
      else:
        seen[cur_key].append(name)
      next_ind = max(next_ind, int(label) + 1)  
    else:
      output_lines.append(line.split('\n')[0])
    cnt += 1


all_keys = []
for key in seen:
  all_keys.append(key)
## deal with size constraints
for key in all_keys:
  ## 16 == max number of slots in a tray
  while (len(seen[key]) > 16):
    new_key = tuple([key[0], key[1], str(next_ind)])
    seen[new_key] = []
    diff = len(seen[key]) - 16
    if (diff > 16):
      print("odd")
    for i in range(0, min(diff, 16)):
      seen[new_key].append(seen[key].pop())
    next_ind += 1
  
cur_ind = 0
proper = {}
## deal with label constraints
for key in seen:
  new_key = tuple([key[0], key[1], str(cur_ind)])
  proper[new_key] = seen[key]
  cur_ind += 1

for key in proper:
  for item in proper[key]:
    output_lines.append(item + " " + key[0] + " " + key[1] + " " + key[2])

for line in output_lines:
  print(line)
