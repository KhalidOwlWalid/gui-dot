#ifndef UTIL_HPP
#define UTIL_HPP

#include "logger.hpp"
#include <type_traits>

#define GUIDOT_ASSERT(eval_expr, msg_if_fail)                     \
  do {                                                            \
    static_assert(std::is_same<decltype(eval_expr), bool>::value,  \
      "Expression must be a boolean");                            \
    if (!eval_expr) {                                             \
      LOG(ERROR, msg_if_fail);                                    \
      return;                                                     \
    }                                                             \
  } while(0)

#endif // UTIL_HPP
