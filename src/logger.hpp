#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <godot_cpp/variant/utility_functions.hpp>

enum class LogLevel {
  DEBUG,
  INFO,
  WARNING,
  ERROR,
};

static const LogLevel DEBUG = LogLevel::DEBUG;
static const LogLevel INFO = LogLevel::INFO;
static const LogLevel WARNING = LogLevel::WARNING;
static const LogLevel ERROR = LogLevel::ERROR;

#define LOG(level, ...)                                                                                                       \
  do {                                                                                                                        \
    switch (level) {                                                                                                          \
      case LogLevel::DEBUG:                                                                                                   \
        UtilityFunctions::print("[DEBUG] ", "(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);            \
        break;                                                                                                                \
      case LogLevel::INFO:                                                                                                    \
        UtilityFunctions::print("[INFO] ", "(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);             \
        break;                                                                                                                \
      case LogLevel::WARNING:                                                                                                 \
        UtilityFunctions::push_warning("(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);                 \
        break;                                                                                                                \
      case LogLevel::ERROR:                                                                                                   \
        UtilityFunctions::push_error("(class: ", __class__, ")", "(func: ", __func__, ") - ", __VA_ARGS__);                   \
        break;                                                                                                                \
    }                                                                                                                         \
  } while (0)                                         

#endif // LOGGER_HPP
