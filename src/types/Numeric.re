#
# Numeric: Methods for the Numeric pseudo-class
# Copyright (C)2008 Tony Arcieri
# 
# Redistribution is permitted under the MIT license.  See LICENSE for details.
#

module Numeric
  def pow(base, exponent)
    result = math::pow(base, exponent)
    if erlang::is_integer(base)
      erlang::round(result)
    else
      result
        
  def funcall(number, ~to_s, [])
    number.to_list().to_string()

  def funcall(number, ~inspect, [])
    funcall(number, ~to_s, [])

  def funcall(number, ~to_list, [])
    if erlang::is_integer(number)
      erlang::integer_to_list(number)
    else
      [list] = io_lib::format("~f".to_list(), [number])

