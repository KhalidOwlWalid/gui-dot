#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <godot_cpp/variant/utility_functions.hpp>

enum class LogLevel {
  DEBUG,
  INFO,
  WARNING,
  ERROR,
};

constexpr LogLevel DEBUG = LogLevel::DEBUG;
constexpr LogLevel INFO = LogLevel::INFO;
constexpr LogLevel WARNING = LogLevel::WARNING;
constexpr LogLevel ERROR = LogLevel::ERROR;

#define LOG(level, ...)                                                                                                       \
  do {                                                                                                                        \
    switch (level) {                                                                                                          \
      case LogLevel::DEBUG:                                                                                                   \
        UtilityFunctions::print("[DEBUG] ", "(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);            \
      case LogLevel::INFO:                                                                                                    \
        UtilityFunctions::print("[INFO] ", "(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);             \
      case LogLevel::WARNING:                                                                                                 \
        UtilityFunctions::push_warning("(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);                 \
      case LogLevel::ERROR:                                                                                                   \
        UtilityFunctions::push_error("(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);                   \
    }                                                                                                                         \
  } while (0)                                         

#endif // LOGGER_HPP
