from typing import Dict, List, Optional
from matplotlib import pyplot as plt
from matplotlib import patches as patches
import re
import os
import copy

class pin:
    def __init__(self, name):
        self.name = name
        self.use = None
        self.direction = None
        self.shape = None
        self.Layers:Dict[str, List[List[float]]] = {}
    def set_name(self, name):
        self.name = name
    
    def set_use(self, use):
        self.use = use
    
    def set_direction(self, direction):
        self.direction = direction
    
    def set_shape(self, shape):
        self.shape = shape
    
    def add_layer(self, layer, rect):
        if layer in self.Layers:
            self.Layers[layer].append(rect)
        else:
            self.Layers[layer] = [rect]
    
    def shift(self, x, y):
        for layer, rects in self.Layers.items():
            for rect in rects:
                if x is not None:
                    rect[0] += x
                    rect[2] += x
                
                if y is not None:
                    rect[1] += y
                    rect[3] += y
            
            for rect in rects:
                for i in range(4):
                    rect[i] = round(rect[i], 6)
    
    def flip(self, x, y):
        if x is not None:
            for layer, rects in self.Layers.items():
                for rect in rects:
                    rect[0] = x - rect[0]
                    rect[2] = x - rect[2]
                
                for rect in rects:
                    for i in range(4):
                        rect[i] = round(rect[i], 6)
        
        if y is not None:
            for layer, rects in self.Layers.items():
                for rect in rects:
                    rect[1] = y - rect[1]
                    rect[3] = y - rect[3]
                
                for rect in rects:
                    for i in range(4):
                        rect[i] = round(rect[i], 6)
    
    
    def __str__(self):
        tab = "\t\t"
        temp_str = f"{tab}PIN {self.name}\n"
        tab += "\t"
        
        if self.use is not None:
            temp_str += f"{tab}USE {self.use} ;\n"
        
        if self.direction is not None:
            temp_str += f"{tab}DIRECTION {self.direction} ;\n"
        
        if self.shape is not None:
            temp_str += f"{tab}SHAPE {self.shape} ;\n"

        if len(self.Layers) != 0:
            temp_str += f"{tab}PORT\n"
        
        tab += "\t"
        for layer, rects in self.Layers.items():
            temp_str += f"{tab}LAYER {layer} ;\n"
            for rect in rects:
                temp_rect = " ".join(map(str, rect))
                temp_str += f"{tab}\tRECT {temp_rect} ;\n"
        
        tabe = tab[:-1]
        temp_str += f"{tabe}END\n"
        tabe = tabe[:-1]
        temp_str += f"{tabe}END {self.name}\n"
        return temp_str

class obs:
    def __init__(self):
        self.Layers:Dict[str, List[List[float]]] = {}
    
    def add_layer(self, layer, rect):
        if layer in self.Layers:
            self.Layers[layer].append(rect)
        else:
            self.Layers[layer] = [rect]
    
    def shift(self, x, y):
        for layer, rects in self.Layers.items():
            for rect in rects:
                if x is not None:
                    rect[0] += x
                    rect[2] += x
                
                if y is not None:
                    rect[1] += y
                    rect[3] += y
            
            for rect in rects:
                for i in range(4):
                    rect[i] = round(rect[i], 6)
    
    def flip(self, x, y):
        if x is not None:
            for layer, rects in self.Layers.items():
                for rect in rects:
                    rect[0] = x - rect[0]
                    rect[2] = x - rect[2]
                
                for rect in rects:
                    for i in range(4):
                        rect[i] = round(rect[i], 6)
        
        if y is not None:
            for layer, rects in self.Layers.items():
                for rect in rects:
                    rect[1] = y - rect[1]
                    rect[3] = y - rect[3]
                
                for rect in rects:
                    for i in range(4):
                        rect[i] = round(rect[i], 6)
    
    def __str__(self):
        tab = "\t\t"
        temp_str = f"{tab}OBS\n"
        tab += "\t"
        for layer, rects in self.Layers.items():
            temp_str += f"{tab}LAYER {layer} ;\n"
            for rect in rects:
                temp_rect = " ".join(map(str, rect))
                temp_str += f"{tab}\tRECT {temp_rect} ;\n"
        
        tabe = tab[:-1]
        temp_str += f"{tabe}END\n"
        return temp_str
    
def update_lbox(lbox, x, y, widht, height):
    if lbox[0] > x:
        lbox[0] = x
    if lbox[1] > y:
        lbox[1] = y

    if lbox[2] < x + widht:
        lbox[2] = x + widht
    
    if lbox[3] < y + height:
        lbox[3] = y + height
    return lbox

class cell:
    def __init__(self, name):
        self.name = name
        self.cls:Optional[str] = None
        self.origin:List[float] = []
        self.foreign:List[float] = []
        self.size_x:Optional[float] = None
        self.size_y:Optional[float] = None
        self.site:Optional[str] = None
        self.symmetry:List[str] = []
        self.pin_list:List[pin] = []
        self.obs:Optional[obs] = None
    
    def set_class(self, cls):
        self.cls = cls
    
    def set_origin(self, origin):
        self.origin = origin
    
    def set_foreign(self, foreign):
        self.foreign = foreign
    
    def set_size(self, size_x, size_y):
        self.size_x = size_x
        self.size_y = size_y
    
    def set_site(self, site):
        self.site = site
    
    def add_symmetry(self, symmetry):
        self.symmetry.append(symmetry)
    
    def add_pin(self, pin):
        self.pin_list.append(pin)
        
    def add_obs(self, obs):
        self.obs = obs
    
    def get_pin(self, pin_name):
        for pin in self.pin_list:
            if pin.name == pin_name:
                return pin
        return None
    
    def shift(self, x, y):
        self.origin[0] += x
        self.origin[1] += y
        for pin in self.pin_list:
            pin.shift(x, y)
        if self.obs is not None:
            self.obs.shift(x, y)
        
    def flip_x(self):
        if self.size_x is None:
            print(f"Error: Size_x:{self.size_x} is None for the cell {self.name}")
            return
            
        for pin in self.pin_list:
            pin.flip(self.origin[0] + self.size_x, None)
            pin.shift(self.origin[0], None)
        if self.obs is not None:
            self.obs.flip(self.origin[0] + self.size_x, None)
            self.obs.shift(self.origin[0], None)
    
    def flip_y(self):
        if self.size_y is None:
            print(f"Error: Size_y:{self.size_y} is None for the cell {self.name}")
            return
        
        for pin in self.pin_list:
            pin.flip(None, self.origin[1] + self.size_y)
            pin.shift(None, self.origin[1])
        if self.obs is not None:
            self.obs.flip(None, self.origin[1] + self.size_y)
            self.obs.shift(None, self.origin[1])
    
    def __str__(self):
        tab = ""
        temp_string = f"{tab}MACRO {self.name}\n"
        tab = "\t"
        if self.cls is not None:
            temp_string += f"{tab}CLASS {self.cls} ;\n"
        
        if len(self.origin) == 2:
            temp_string += f"{tab}ORIGIN {self.origin[0]} {self.origin[1]} ;\n"
        
        if len(self.foreign) == 2:
            temp_string += f"{tab}FOREIGN {self.name} {self.foreign[0]} {self.foreign[1]} ;\n"
        
        if self.size_x is not None and self.size_y is not None:
            temp_string += f"{tab}SIZE {self.size_x} BY {self.size_y} ;\n"
        
        if len(self.symmetry) != 0:
            temp_string += f"{tab}SYMMETRY"
            for sym in self.symmetry:
                temp_string += f" {sym}"
            temp_string += " ;\n"
        
        if self.site is not None:
            temp_string += f"{tab}SITE {self.site} ;\n"
        
        
        for pin in self.pin_list:
            temp_string += str(pin)
        
        if self.obs is not None:
            temp_string += str(self.obs)
        
        tab = tab[:-1]
        temp_string += f"{tab}END {self.name}\n"
        return temp_string

    def plot_cell(self):
        
        ## Ensure size_x and size_y are not None
        if self.size_x is None or self.size_y is None:
            print(f"Error: Size_x:{self.size_x} or size_y:{self.size_y} is None for the cell {self.name}")
            return
        ## Plot a box with size_x and size_y with origin as the center
        widht = self.size_x
        height = self.size_y
        fig, ax = plt.subplots(figsize=(widht*20, height*20))
        x_origin = self.origin[0]
        y_origin = self.origin[1]
        rect = patches.Rectangle((x_origin, y_origin), widht, height,
                                 facecolor='none', linewidth=1, edgecolor='r')
        lbox = [x_origin, y_origin, x_origin + widht, y_origin + height]
        ax.add_patch(rect)
        
        ## Add box for each pin in the cell and plot the pin name and ensure 
        ## that all the layers get same color fill
        
        colors = ['r', 'g', 'b', 'c', 'm', 'y', 'k']
        cid = 0
        alpha = 0.6
        color_map = {}
        for pin in self.pin_list:
            for layer, rects in pin.Layers.items():
                if layer not in color_map:
                    color_map[layer] = colors[cid]
                    cid = (cid + 1) % len(colors)
                color = color_map[layer]
                for rect in rects:
                    x = rect[0]
                    y = rect[1]
                    widht = rect[2] - rect[0]
                    height = rect[3] - rect[1]
                    rect = patches.Rectangle((x, y), widht, height,
                                             linewidth=1, color=color,
                                             alpha=alpha)
                    ax.add_patch(rect)
                    x_mid = x + widht/2
                    y_mid = y + height/2
                    ax.text(x_mid, y_mid, pin.name, fontsize=12, color=color)
                    lbox = update_lbox(lbox, x, y, widht, height)
        
        if self.obs is not None:
            for layer, rects in self.obs.Layers.items():
                if layer not in color_map:
                    color_map[layer] = colors[cid]
                    cid = (cid + 1) % len(colors)
                color = color_map[layer]
                for rect in rects:
                    x = rect[0]
                    y = rect[1]
                    widht = rect[2] - rect[0]
                    height = rect[3] - rect[1]
                    rect = patches.Rectangle((x, y), widht, height,
                                             linewidth=1, color=color,
                                             alpha=alpha/2)
                    ax.add_patch(rect)
                    lbox = update_lbox(lbox, x, y, widht, height)

        ## Remove the axis
        ax.axis('off')
        box_widht = lbox[2] - lbox[0]
        box_height = lbox[3] - lbox[1]
        threshold = 0.05
        ax.set_xlim(lbox[0] - threshold*box_widht, lbox[2] + threshold*box_widht)
        ax.set_ylim(lbox[1] - threshold*box_height, lbox[3] + threshold*box_height)
                
class site:
    def __init__(self) -> None:
        self.name = None
        self.size:List[float] = []
        self.symmetry:List[str] = []
        self.cls = None
    
    def set_name(self, name):
        self.name = name
    
    def set_size(self, size):
        self.size.append(size)
    
    def add_symmetry(self, symmetry):
        self.symmetry.append(symmetry)
    
    def set_class(self, cls):
        self.cls = cls
    
    def __str__(self):
        tab = ""
        temp_string = f"{tab}SITE {self.name}\n"
        tab = "\t"
        if self.cls is not None:
            temp_string += f"{tab}CLASS {self.cls} ;\n"
        
        if len(self.size) == 2:
            temp_string += f"{tab}SIZE {self.size[0]} BY {self.size[1]} ;\n"
        else:
            ## Print error that size is not correct for the site
            print(f"Error: Size:{self.size} is not correct for the site {self.name}")
        
        if len(self.symmetry) != 0:
            temp_string += f"{tab}SYMMETRY"
            for sym in self.symmetry:
                temp_string += f" {sym}"
            temp_string += " ;\n"
        
        tab = tab[:-1]
        temp_string += f"{tab}END {self.name}\n"
        return temp_string

class lef:
    def __init__(self, lef_file):
        self.lef_file = lef_file
        
        ## Check the lef file exists
        if not os.path.exists(lef_file):
            print(f"Error: LEF file {lef_file} does not exist")
            return
        self.cells:List[cell] = []
        self.sites:List[site] = []

    def lef_parser(self):
        empty_line = re.compile(r'^\s*$')
        comment_line = re.compile(r'^\s*#')
        only_end = re.compile(r'^\s*END\s*$')
        fp = open(self.lef_file, 'r')
        
        macro_flag = False
        site_flag = False
        pin_flag = False
        obs_flag = False
        obs_layer = None
        pin_layer = None
        
        for line in fp:
            if empty_line.match(line) or comment_line.match(line):
                continue
            
            items = line.split()
            line = line.strip()
            ## Read sites
            if line.startswith("SITE") and not macro_flag:
                site_flag = True
                temp_site = site()
                temp_site.set_name(items[1])
                self.sites.append(temp_site)
                # print(f"1. In Site: {line}")
                continue
            
            if site_flag:
                # print(f"2. In Site: {line}")
                temp_site = self.sites[-1]
                
                if line.startswith("SIZE"):
                    temp_site.set_size(float(items[1]))
                    temp_site.set_size(float(items[3]))
                    
                elif line.startswith("SYMMETRY"):
                    for sym in items[1:-1]:
                        temp_site.add_symmetry(sym)
            
                elif line.startswith("CLASS"):
                    temp_site.set_class(items[1])
                
                elif line.startswith("END"):
                    site_flag = False
                
                
                continue
            
            ## Read cells
            if line.startswith("MACRO"):
                macro_flag = True
                temp_cell = cell(items[1])
                self.cells.append(temp_cell)
                continue
            
            if macro_flag:
                line = line.strip()
                # print(f"1. Now at line: {line}")
                temp_cell = self.cells[-1]
                
                if line.startswith("CLASS"):
                    temp_cell.set_class(items[1])
                
                elif line.startswith("ORIGIN"):
                    temp_cell.set_origin([float(items[1]), float(items[2])])
                
                elif line.startswith("FOREIGN"):
                    temp_cell.set_foreign([float(items[2]), float(items[3])])
                    
                elif line.startswith("SIZE"):
                    temp_cell.set_size(float(items[1]), float(items[3]))
                    
                elif line.startswith("SITE"):
                    temp_cell.set_site(items[1])
                
                elif line.startswith("SYMMETRY"):
                    for sym in items[1:-1]:
                        temp_cell.add_symmetry(sym)
                
                elif line.startswith("PIN"):
                    temp_pin = pin(items[1])
                    temp_cell.add_pin(temp_pin)
                    # print(f"2. Now at line: PIN {temp_pin.name} {line}")
                    pin_flag = True
                
                elif line.startswith("OBS"):
                    obs_flag = True
                    temp_obs = obs()
                    temp_cell.add_obs(temp_obs)
                
                elif pin_flag:
                    temp_pin = temp_cell.pin_list[-1]
                    if line.startswith("USE"):
                        temp_pin.set_use(items[1])
                    elif line.startswith("DIRECTION"):
                        temp_pin.set_direction(items[1])
                    elif line.startswith("SHAPE"):
                        temp_pin.set_shape(items[1])
                    elif line.startswith("PORT"):
                        continue
                    elif line.startswith("LAYER"):
                        pin_layer = items[1]
                    elif line.startswith("RECT"):
                        temp_pin.add_layer(pin_layer, [float(items[1]),
                                                       float(items[2]),
                                                       float(items[3]),
                                                       float(items[4])])
                    elif only_end.match(line):
                        continue
                    elif line.startswith("END") and items[1] == temp_pin.name:
                        # print(f"Now at line: END {temp_pin.name}")
                        pin_flag = False
                        pin_layer = None
                    else:
                        print(f"Error: Unknown pin attribute {line}")
                
                elif obs_flag and temp_cell.obs is not None:
                    temp_obs = temp_cell.obs
                    if line.startswith("LAYER"):
                        obs_layer = items[1]
                    elif line.startswith("RECT"):
                        temp_obs.add_layer(obs_layer, [float(items[1]),
                                                       float(items[2]),
                                                       float(items[3]),
                                                       float(items[4])])
                    elif line.startswith("END"):
                        obs_flag = False
                        obs_layer = None
                    else:
                        print(f"Error: Unknown obs attribute {line}")
                
                elif line.startswith("END") and items[1] == temp_cell.name:
                    macro_flag = False
                    
                else:
                    print(f"Error: Unknown cell:{temp_cell.name} attribute {line}")
                
                continue
            
            print(f"Error: Unknown line {line}")
        fp.close()

def gen_multi_bit_flop(lef_file:str, base_cell:str, new_cell:str, rows:int, column:int):
    lef_obj = lef(lef_file)
    lef_obj.lef_parser()
    ## Print Sites ##
    # for temp_site in lef_obj.sites:
    #     print(temp_site.name)
    
    i = 0
    ref_cell = None
    while  i < len(lef_obj.cells):
        if base_cell == lef_obj.cells[i].name:
            ref_cell = lef_obj.cells[i]
            break
        i += 1
    
    if ref_cell is None:
        print(f"Error: cell {base_cell} not found in the lef file {lef_file}")
        return
    
    ## Get the pin names
    sig_pins = []
    clk_pin = None
    power_pin = None
    ground_pin = None
    cell_site = ref_cell.site
    
    for cell_pin in ref_cell.pin_list:
        if cell_pin.use == "SIGNAL":
            sig_pins.append(cell_pin.name)
        elif cell_pin.use == "CLOCK":
            clk_pin_name = cell_pin.name
        elif cell_pin.use == "POWER":
            power_pin_name = cell_pin.name
        elif cell_pin.use == "GROUND":
            ground_pin_name = cell_pin.name
        else:
            print(f"Error: Unknown pin use {cell_pin.use} for pin {cell_pin.name}")
    
    ## Ensure all the pins are found
    if clk_pin_name is None:
        print(f"Error: Clock pin not found in the cell {ref_cell.name}")
        return

    if power_pin_name is None:
        print(f"Error: Power pin not found in the cell {ref_cell.name}")
        return

    if ground_pin_name is None:
        print(f"Error: Ground pin not found in the cell {ref_cell.name}")
        return

    if len(sig_pins) == 0:
        print(f"Error: No signal pins found in the cell {ref_cell.name}")
        return
    
    if cell_site is None:
        print(f"Error: Site not found in the cell {ref_cell.name}")
        return
    
    mbff_cell = cell(new_cell)
    mbff_cell.set_class(ref_cell.cls)
    mbff_cell.set_origin(ref_cell.origin)
    mbff_cell.set_foreign(ref_cell.foreign)
    
    if ref_cell.size_x is None or ref_cell.size_y is None:
        print(f"Error: Size_x:{ref_cell.size_x} or size_y:{ref_cell.size_y} is"
              f" None for the cell {ref_cell.name}")
        return  
    
    mbff_cell.set_size(ref_cell.size_x*column, ref_cell.size_y*rows)
    
    mbff_cell.set_site(f"{ref_cell.site}_R{rows}")
    for sym in ref_cell.symmetry:
        mbff_cell.add_symmetry(sym)
    
    
    for i in range(rows):
        for j in range(column):
            temp_cell = copy.deepcopy(ref_cell)
            if i%2 == 1:
                temp_cell.flip_y()
            
            temp_cell.shift(j*ref_cell.size_x, i*ref_cell.size_y)
            
            ## For the first row add both power and ground pins
            if i == 0 and j == 0:
                ## First add power pin
                power_pin = copy.deepcopy(temp_cell.get_pin(power_pin_name))
                mbff_cell.add_pin(power_pin)
                
                ## Next add ground pin
                ground_pin = copy.deepcopy(temp_cell.get_pin(ground_pin_name))
                mbff_cell.add_pin(ground_pin)
                
                ## Next add the clock pin
                clk_pin = copy.deepcopy(temp_cell.get_pin(clk_pin_name))
                mbff_cell.add_pin(clk_pin)
            else:
                if i % 2 == 1:
                    ## Only add the ground pin layer
                    ground_pin = copy.deepcopy(temp_cell.get_pin(ground_pin_name))
                    
                    if ground_pin is None:
                        print(f"Error: Ground pin {ground_pin_name} not found"
                              f" in the cell {temp_cell.name}")
                        return
                    
                    mbff_groun_pin = mbff_cell.get_pin(ground_pin_name)
                    
                    if mbff_groun_pin is None:
                        print(f"Error: Ground pin {ground_pin_name} not found"
                              f" in the cell {mbff_cell.name}")
                        return
                    
                    for layer, rects in ground_pin.Layers.items():
                        for rect in rects:
                            mbff_groun_pin.add_layer(layer, rect)
                else:
                    ## Only add the power pin layer
                    power_pin = copy.deepcopy(temp_cell.get_pin(power_pin_name))
                    
                    if power_pin is None:
                        print(f"Error: Power pin {power_pin_name} not found"
                              f" in the cell {temp_cell.name}")
                        return

                    mbff_power_pin = mbff_cell.get_pin(power_pin_name)
                    
                    if mbff_power_pin is None:
                        print(f"Error: Power pin {power_pin_name} not found"
                              f" in the cell {mbff_cell.name}")
                        return
                    
                    for layer, rects in power_pin.Layers.items():
                        for rect in rects:
                            mbff_power_pin.add_layer(layer, rect)
                    
                    if i == 0:
                        ground_pin = copy.deepcopy(temp_cell.get_pin(ground_pin_name))
                        
                        if ground_pin is None:
                            print(f"Error: Ground pin {ground_pin_name} not found"
                                  f" in the cell {temp_cell.name}")
                            return
                        
                        mbff_groun_pin = mbff_cell.get_pin(ground_pin_name)
                        
                        if mbff_groun_pin is None:
                            print(f"Error: Ground pin {ground_pin_name} not found"
                                  f" in the cell {mbff_cell.name}")
                            return
                        
                        for layer, rects in ground_pin.Layers.items():
                            for rect in rects:
                                mbff_groun_pin.add_layer(layer, rect)

                ## Add the clock pin layer
                clk_pin = copy.deepcopy(temp_cell.get_pin(clk_pin_name))
                
                if clk_pin is None:
                    print(f"Error: Clock pin {clk_pin_name} not found"
                          f" in the cell {temp_cell.name}")
                    return
                
                mbff_clk_pin = mbff_cell.get_pin(clk_pin_name)
                
                if mbff_clk_pin is None:
                    print(f"Error: Clock pin {clk_pin_name} not found"
                          f" in the cell {mbff_cell.name}")
                    return
                
                for layer, rects in clk_pin.Layers.items():
                    for rect in rects:
                        mbff_clk_pin.add_layer(layer, rect)
                
            pin_suffix = f"{i*column + j}"
            for sig_pin in sig_pins:
                temp_sig_pin = copy.deepcopy(temp_cell.get_pin(sig_pin))
                if temp_sig_pin is None:
                    print(f"Error: Signal pin {sig_pin} not found in the cell"
                          f" {temp_cell.name}")
                    return 
                
                temp_sig_pin.set_name(f"{sig_pin}{pin_suffix}")
                mbff_cell.add_pin(temp_sig_pin)
            
            ## Add the obs layer
            if temp_cell.obs is not None:
                temp_obs = copy.deepcopy(temp_cell.obs)
                if mbff_cell.obs is None:
                    mbff_cell.add_obs(temp_obs)
                else:
                    for layer, rects in temp_obs.Layers.items():
                        for rect in rects:
                            mbff_cell.obs.add_layer(layer, rect)
    
    ## Generate site for the new cell
    new_site = site()
    i = 0
    ref_site = None
    while len(lef_obj.sites) > i:
        if lef_obj.sites[i].name == cell_site:
            ref_site = lef_obj.sites[i]
            break
        i += 1
    
    if ref_site is None:
        print(f"Error: Site {cell_site} not found in the lef file {lef_file}")
        return mbff_cell, None
    
    new_site.set_name(f"{cell_site}_R{rows}")
    new_site.set_size(ref_site.size[0])
    new_site.set_size(ref_site.size[1]*rows)
    new_site.symmetry = ref_site.symmetry
    new_site.set_class(ref_site.cls)
    
    return mbff_cell, new_site


def add_clk_pin_layer(mbff, num_rows, num_cols):
    width = 0.018
    ## Add M2 horizontal layers
    base_x = 0.108
    base_y = 0.072
    
    cell_height = mbff.size_y / num_rows
    cell_width = mbff.size_x / num_cols
    
    max_y = mbff.origin[1]    
    for i in range(num_rows):
        x = base_x - 2*width
        x = round(x, 6)
        
        if i%2 == 0:
            y = base_y + i*cell_height
        else:
            y = (i+1)*cell_height - base_y - 1*width
        
        y = round(y, 6)
        x1 = x + cell_width*(num_cols - 1) + 8*width
        x1 = round(x1, 6)
        y1 = round(y + width, 6)
        rect = [x, y, x1, y1]
        clk_pin = mbff.get_pin('CLK')
        clk_pin.add_layer('M2', rect)
        
        ## Add V1 Vias
        max_y = max(max_y, y)
        for j in range(num_cols):
            x = base_x + j*cell_width - width/2
            x = round(x, 6)
            x1 = round(x + width, 6)
            y1 = round(y + width, 6)
            rect = [x, y, x1, y1]
            clk_pin.add_layer('V1', rect)
            
    ## Add M3 vertical layers
    base_x = 0.171
    # base_y = 0.090
    
    rect = [base_x, round(base_y - width, 6), round(base_x + width, 6),
            round(max_y + 2*width, 6)]
    
    clk_pin = mbff.get_pin('CLK')
    clk_pin.add_layer('M3', rect)
    
    ## Add V2 vias
    x = base_x
    for i in range(num_rows):
        if i%2 == 0:
            y = base_y + i*cell_height
        else:
            y = (i+1)*cell_height - base_y - 1*width
        y = round(y, 6)
        x1 = round(x + width, 6)
        y1 = round(y + width, 6)
        rect = [x, y, x1, y1]
        clk_pin.add_layer('V2', rect)
    
    return

## Write lef file for a given cell and site and output lef file name
def gen_lef_file(cell, site, lef_file):
    fp = open(lef_file, 'w')
    fp.write("VERSION 5.8 ;\n")
    fp.write("BUSBITCHARS \"[]\" ;\n")
    fp.write("DIVIDERCHAR \"/\" ;\n\n")
    
    fp.write(str(site).replace("\t", "  "))
    fp.write("\n")
    fp.write(str(cell).replace("\t", "  "))
    fp.write("\nEND LIBRARY\n")
    fp.close()
    return

if __name__ == "__main__":
    vts = ["L", "R", "SL"]
    configs = [(2, 1), (4, 1), (4, 2), (8, 2)]
    output_dir = ""
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for vt in vts:
        lef_file = f""
        cell_list = [f'DFFHQNx1_ASAP7_75t_{vt}', f'DFFHQNx2_ASAP7_75t_{vt}',
                    f'DFFHQNx3_ASAP7_75t_{vt}']
        
        for ff_cell in cell_list:
            for row, column in configs:
                prefix = f"DFFHQNV{row}"
                if column > 1:
                    prefix += f"H{column}"
                prefix += "X"

                new_cell_name = re.sub("DFFHQN", f"{prefix}", ff_cell)
                output_lef_file = f"{output_dir}/{new_cell_name}.lef"
                new_cell, new_site = gen_multi_bit_flop(lef_file, ff_cell,
                                                        new_cell_name, row,
                                                        column)
                add_clk_pin_layer(new_cell, row, column)
                gen_lef_file(new_cell, new_site, output_lef_file)
                print(f"Generated LEF file {output_lef_file}")

            
