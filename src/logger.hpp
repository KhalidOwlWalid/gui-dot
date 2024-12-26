#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <godot_cpp/variant/utility_functions.hpp>

// TODO (Khalid): Add logging level
#define LOG(...) UtilityFunctions::print("(class)", __class__, " : (func)", __func__, " - ", __VA_ARGS__);

#endif
