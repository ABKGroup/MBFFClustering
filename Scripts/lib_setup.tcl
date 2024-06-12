# This script was written and developed by XXXX. However, the underlying commands and reports are copyrighted by Cadence. 
# We thank Cadence for granting permission to share our research to help promote and foster the next generation of innovators.

### lib and lef, RC setup

set ref_dir "../"
set libdir "${ref_dir}/ASAP7/lib_3VT_TT"
set lefdir "${ref_dir}/ASAP7/lef_3VT_TT"
set qrcdir "${ref_dir}/ASAP7/qrc"
set mbfflefdir "${ref_dir}/ASAP7/mbff_lef"
set mbff_lefs [glob ${mbfflefdir}/*.lef]

set_db init_lib_search_path { \
    ${libdir} \
    ${lefdir} \
}

set libworst ""
lappend libworst "${libdir}/asap7sc7p5t_AO_LVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_AO_RVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_AO_SLVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_INVBUF_LVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_INVBUF_RVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_INVBUF_SLVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_OA_LVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_OA_RVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_OA_SLVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_SEQ_LVT_TT_nldm_201020_mbff.lib"
lappend libworst "${libdir}/asap7sc7p5t_SEQ_RVT_TT_nldm_201020_mbff.lib"
lappend libworst "${libdir}/asap7sc7p5t_SEQ_SLVT_TT_nldm_201020_mbff.lib"
lappend libworst "${libdir}/asap7sc7p5t_SIMPLE_LVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_SIMPLE_RVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/asap7sc7p5t_SIMPLE_SLVT_TT_nldm_201020.lib"
lappend libworst "${libdir}/sram_asap7_32x256_1rw.lib"
lappend libworst "${libdir}/sram_asap7_64x64_1rw.lib"
lappend libworst "${libdir}/sram_asap7_256x128_1rw.lib"
lappend libworst "${libdir}/sram_asap7_32x128_1rw.lib"

set libbest $libworst

set lefs "  
    ${lefdir}/asap7_tech_1x_201209.lef \
    ${lefdir}/asap7sc7p5t_27_R_1x_201211.lef \
    ${lefdir}/asap7sc7p5t_27_L_1x_201211.lef \
    ${lefdir}/asap7sc7p5t_27_SL_1x_201211.lef \
    ${lefdir}/sram_asap7_16x256_1rw.lef \
    ${lefdir}/sram_asap7_32x256_1rw.lef \
    ${lefdir}/sram_asap7_64x64_1rw.lef \
    ${lefdir}/sram_asap7_256x128_1rw.lef \
    ${lefdir}/sram_asap7_32x128_1rw.lef \
    "

set lefs [concat $lefs $mbff_lefs]

set qrc_max "${qrcdir}/ASAP7.tch"
set qrc_min "${qrcdir}/ASAP7.tch"
#
# Ensures proper and consistent library handling between Genus and Innovus
#set_db library_setup_ispatial true
setDesignMode -process 7
