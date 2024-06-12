#include "ArgumentParser.h"
#include "ParamMgr.h"

void parseGeneric(po::options_description& generic)
{
    generic.add_options()
    ("help,h", "show this message\n");
}
void parseHidden(po::options_description& hidden)
{
    auto& paramMgr = clustering::getParamMgr();
    hidden.add_options()
    ("inputFile, -i", po::value<std::string> (& (paramMgr.reg_file))->default_value ("None"), "input filename")
    ("outputFile, -o", po::value<std::string> (& (paramMgr.out_file))->default_value ("None"), "output filename");

}
void parseConfig(po::options_description& config)
{
    auto& paramMgr = clustering::getParamMgr();
    config.add_options()
    ("M", po::value<int> (&paramMgr.M)->default_value (10), "Integer. The M-th nearest neighbor on which the bandwidth selection will be based.\n")
    ("K", po::value<int> (&paramMgr.K)->default_value (140), "Integer. The number of nearest neighbors that will be taken into account when calculating the effective mean shift vector.\n")
    ("ThreadNum", po::value<int> (&paramMgr.ThreadNum)->default_value (20), "Integer. The number of threads for parallel computing.\n")
    ("Tol", po::value<double> (&paramMgr.Tol)->default_value (0.0001), "Double. The convergence criterion for the effective mean shift algorithm. When the shifted distance of a flip-flop across two consecutive iterations is smaller than this value, it is considered converged.\n")
    ("Epsilon", po::value<double> (&paramMgr.Epsilon)->default_value (0.5), "Double. The merging criterion to compensate for approximation error. The larger the epsilon, the fewer the clusters.\n")
    ("MaxDisp", po::value<double> (&paramMgr.MaxDisp)->default_value (3e+5), "Double. The maximum allowed displacement.\n")
    ("MaxBandwidth", po::value<double> (&paramMgr.MaxBandwidth), "Double. The maximum cutoff bandwidth in effective mean shift. When a flip-flop has a bandwidth larger than this value, it will be cut off to be MaxBandwidth. Default value is set to one third of MaxDisp.\n")
    ("MaxClusterSize", po::value<int> (&paramMgr.MaxClusterSize)->default_value (16), "Integer. The maximum number of flip-flops a multi-bit flip-flop can accomodate.\n");
}
bool parseArguments(int argc, char* argv[])
{
    try
    {
        po::options_description hidden ("Hidden Options");
        po::options_description generic ("General");
        po::options_description config ("Configuration");
        parseHidden(hidden);
        parseGeneric(generic);
        parseConfig(config);


        po::options_description cmdlineOpt;
        cmdlineOpt.add (hidden).add (config).add (generic);

        po::options_description visible ("Options");
        visible.add (config).add (generic);

        po::positional_options_description posOpt;
        posOpt.add ("inputFile", 1);
        posOpt.add ("outputFile", 1);
        po::variables_map vm;
        po::store (po::command_line_parser (argc, argv).options (cmdlineOpt).positional (posOpt).run(), vm);
        po::notify (vm);
        if ( vm.count ("help")  )
        {
            std::cout << "-- Option Descriptions --" << std::endl;
            std::cout << "Timing Unit: ps          " << std::endl;
            std::cout << "Layout Unit: 5e-4 nm     " << std::endl;
            std::cout << "                         " << std::endl;
            std::cout << visible                     << std::endl;
            return false;

        }
        if ( vm.count ("inputFile") )
        {
            if ( !vm["inputFile"].as<std::string>().compare ("None") )
            {
                std::cerr << "ERROR: Input file not specified!" << std::endl;
                return false;
            }
        }
        if ( vm.count ("outputFile") )
        {
            if ( !vm["outputFile"].as<std::string>().compare ("None") )
            {
                std::cerr << "ERROR: Output file not specified!" << std::endl;
                return false;
            }
        }
        if ( !vm.count ("MaxBandwidth") )
        {
            clustering::getParamMgr().MaxBandwidth = vm["MaxDisp"].as<double>()/3;
        }
        showConfig();
    }
    catch (po::required_option& e)
    {
        std::cerr << "ERROR: " << e.what() << std::endl << std::endl;
        return false;
    }
    catch (po::error& e)
    {
        std::cerr << "ERROR: " << e.what() << std::endl << std::endl;
        return false;
    }
    catch (std::exception& e)
    {
        std::cerr << "Unhandled Exception reached: " << e.what() << ", exiting" << std::endl;
        return false;
    }
    return true;
}
void showConfig()
{
    auto& paramMgr = clustering::getParamMgr();
    using std::cout;
    using std::endl;
    cout << "------------ Option Configuration ----------" << endl;
    cout << "-- Input file                            : " << paramMgr.reg_file << endl;
    cout << "-- Output file                           : " << paramMgr.out_file << endl;
    cout << "-- M            (bandwidth reference)    : " << paramMgr.M << endl;
    cout << "-- K            (neighbors considered)   : " << paramMgr.K << endl;
    cout << "-- Tol          (convergence criterion)  : " << paramMgr.Tol << endl;
    cout << "-- Epsilon      (merging criterion)      : " << paramMgr.Epsilon << endl;
    cout << "-- MaxDisp      (displacement constraint): " << paramMgr.MaxDisp << endl;
    cout << "-- MaxBandwidth (bandwidth threshold)    : " << paramMgr.MaxBandwidth << endl;
    cout << "-- ThreadNum                             : " << paramMgr.ThreadNum << endl;
    cout << "--------------------------------------------" << endl;
}
