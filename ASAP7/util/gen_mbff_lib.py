from liberty.parser import parse_liberty
from liberty import parser
import copy
import numpy as np

def update_leakage(cell):
    groups = cell.get_groups('leakage_power')
    for group in groups:
        ## Check if when attribute is present
        flag = False
        for attr in group.attributes:
            if attr.name == 'when':
                flag = True
                break
        ## Remove the group if when attribute is present from the cell
        if flag:
            cell.groups.remove(group)

def scale_leakage_power(cell, scaling_factor):
    groups = cell.get_groups('leakage_power')
    for group in groups:
        for attr in group.attributes:
            if attr.name == 'value':
                attr.value *= scaling_factor

def scale_cell_area(cell, scaling_factor):
    for attr in cell.attributes:
        if attr.name == 'area':
            attr.value *= scaling_factor
            return

def get_power(group):
    rise_power = group.get_group('rise_power')
    frvalue = rise_power.get_array('values')[0][0]
    fall_power = group.get_group('fall_power')
    ffvalue = fall_power.get_array('values')[0][0]
    if frvalue == 0.0 or ffvalue == 0.0:
        return -1.0
    return (frvalue + ffvalue) / 2

def get_delay(group):
    rise_c = group.get_group('rise_constraint')
    frvalue = rise_c.get_array('values')[0][0]
    fall_c = group.get_group('fall_constraint')
    ffvalue = fall_c.get_array('values')[0][0]
    
    if frvalue == 0.0 or ffvalue == 0.0:
        return -1.0
    
    return (frvalue + ffvalue) / 2

def scale_power_table(table, scaling_factor):
    # if scaling_factor == 1.0:
    #     return
    
    transArr = table.get_array('index_1')[0]
    values = table.get_array('values')
    newArr = np.copy(values)
    
    table_attr = [attr.name for attr in table.attributes]
    
    if 'index_2' not in table_attr:
        for i in range(len(transArr)):
            newArr[0][i] *= scaling_factor
        
        table['values'].clear()
        table.attributes.pop(1)
        table.set_array('values', newArr)
        return
        
    capArr = table.get_array('index_2')[0]
    for i in range(len(transArr)):
        for j in range(len(capArr)):
            newArr[i][j] *= scaling_factor
    
    table['values'].clear()
    table.attributes.pop(2)
    table.set_array('values', newArr)

def scale_pin_power(pin, scaling_factor = 1.0):
    pin_powers = pin.get_groups('internal_power')
    for power in pin_powers:
        risetables = power.get_groups('rise_power')
        falltables = power.get_groups('fall_power')
        for table in risetables:
            scale_power_table(table, scaling_factor)
        for table in falltables:
            scale_power_table(table, scaling_factor)

def scale_clk_power(clk_pin, scaling_factor = 1.0):
    pin_powers = clk_pin.get_groups('internal_power')
    for power in pin_powers:
        risetables = power.get_groups('rise_power')
        falltables = power.get_groups('fall_power')
        for table in risetables:
            scale_power_table(table, scaling_factor)
        for table in falltables:
            scale_power_table(table, scaling_factor)

def update_cp_internal_power(clk_pin):
    groups = clk_pin.get_groups('internal_power')
    pg_pin_group = {}
    for group in groups:
        pg_pin = group.get_attribute('related_pg_pin')
        if pg_pin in pg_pin_group:
            if get_power(group) > get_power(pg_pin_group[pg_pin]):
                pg_pin_group[pg_pin] = group
        else:
            pg_pin_group[pg_pin] = group
    
    for group in groups:
        pg_pin = group.get_attribute('related_pg_pin')
        power = get_power(group)
        ref_power = get_power(pg_pin_group[pg_pin])
        if power != ref_power:
            clk_pin.groups.remove(group)
        else:
            ## remove when attribute
            group.attributes = [attr for attr in group.attributes if attr.name != 'when']

def update_cp_timing(clk_pin):
    groups = clk_pin.get_groups('timing')
    best_group = None
    for group in groups:
        if best_group is None:
            best_group = group
        else:
            if get_delay(group) > get_delay(best_group):
                best_group = group
    
    for group in groups:
        if group != best_group:
            clk_pin.groups.remove(group)
        else:
            ## remove sdf_cond and when attribute
            group.attributes = [attr for attr in group.attributes if attr.name not in ['when', 'sdf_cond']]

def get_bundle(ref_pin, pin_name, count):
    bundle = parser.Group('bundle', [pin_name])
    bundle['members'] = [f"{pin_name}{i}" for i in range(count)]
    temp_pin = copy.deepcopy(ref_pin)
    
    attrs = ['direction', 'function', 'power_down_function',
             'related_ground_pin', 'related_power_pin']

    for attr in temp_pin.attributes:
        if attr.name in attrs:
            bundle[attr.name] = attr.value
    
    temp_pin.attributes = [attr for attr in temp_pin.attributes if attr.name not in attrs]

    for i in range(count):
        new_pin = copy.deepcopy(temp_pin)
        new_pin.args[0] = f"{pin_name}{i}"
        bundle.groups.append(new_pin)
    
    return bundle

def generate_new_cell(cell, new_cell_name, bit_count, pin_names = ['D', 'QN'],
                      clk_pin_name = 'CLK', power_scaling_factor = 1.0,
                      area_scaling_factor = 1.0):
    new_cell = copy.deepcopy(cell)
    new_cell.args[0] = new_cell_name
    
    ## Update clock pin power
    clk_pin = new_cell.get_group('pin', clk_pin_name)
    clk_pin_power_factor = bit_count * power_scaling_factor
    scale_pin_power(clk_pin, clk_pin_power_factor)
    scale_leakage_power(new_cell, clk_pin_power_factor)
    scale_cell_area(new_cell, area_scaling_factor*bit_count)
    
    for pin_name in pin_names:
        ref_pin = new_cell.get_group('pin', pin_name)
        scale_pin_power(ref_pin, power_scaling_factor)
        bundle = get_bundle(ref_pin, pin_name, bit_count)
        ## Remove the reference pin from the new_cell
        new_cell.groups.remove(ref_pin)
        new_cell.groups.append(bundle)
    
    ff_banks = new_cell.get_groups('ff')
    ff_banks[0].group_name = f"ff_bank"
    ff_banks[0].args.append(f"{bit_count}") 
    return new_cell

def add_mbff_to_library(library_file, cell_list, bit_count_list,
                        power_scaling_factors, area_scaling_factors):
    with open(library_file, 'r') as fp:
        library = parse_liberty(fp.read())
    for cell in cell_list:
        ## Update the current cell
        lib_cell = library.get_group('cell', cell)
        update_leakage(lib_cell)
        clk_pin = lib_cell.get_group('pin', 'CLK')
        update_cp_internal_power(clk_pin)
        update_cp_timing(clk_pin)
    
        for i, bit_count in enumerate(bit_count_list):
            new_cell_name = f"{cell}_{bit_count}"
            new_lib_cell = generate_new_cell(lib_cell, new_cell_name, bit_count,
                                power_scaling_factor = power_scaling_factors[i],
                                area_scaling_factor = area_scaling_factors[i])
            library.groups.append(new_lib_cell)
    return library

def write_lib(library, lib_file):
    with open(lib_file, 'w') as fp:
        fp.write(str(library))
    return

if __name__ == "__main__":
    vts = ['SL', 'L', 'R']
    for vt in vts:
        base_dir = ""
        lib_file = f"{base_dir}/asap7sc7p5t_SEQ_{vt}VT_FF_nldm_201020.lib"
        cell_list = [f'DFFHQNx1_ASAP7_75t_{vt}', f'DFFHQNx2_ASAP7_75t_{vt}',
                    f'DFFHQNx3_ASAP7_75t_{vt}']
        output_lib_file = f"{base_dir}/asap7sc7p5t_SEQ_{vt}VT_FF_nldm_201020_mbff.lib"
        bit_count_list = [2, 4, 8, 16]
        power_scaling_factors = [0.9, 0.875, 0.854, 0.85]
        area_scaling_factors = [1.0, 1.0, 1.0, 1.0]
        library = add_mbff_to_library(lib_file, cell_list, bit_count_list,
                                    power_scaling_factors, area_scaling_factors)
        write_lib(library, output_lib_file)

"""
sed -i "s@DFFHQNx\(\S*\)_2@DFFHQNV2Xx\1@" *mbff.lib
sed -i "s@DFFHQNx\(\S*\)_4@DFFHQNV4Xx\1@" *mbff.lib
sed -i "s@DFFHQNx\(\S*\)_8@DFFHQNV4H2Xx\1@" *mbff.lib
sed -i "s@DFFHQNx\(\S*\)_16@DFFHQNV8H2Xx\1@" *mbff.lib
"""
