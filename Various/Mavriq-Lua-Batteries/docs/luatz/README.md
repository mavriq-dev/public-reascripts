# luatz

A lua library for time and date manipulation.

Features include:

  - Normalisation of broken down date objects
	  - allows for complex time/date manipulation logic e.g. "What day is it in 2 days, 5 hours from now?"
  - Conversion between locations (time zones) using your local [zoneinfo](https://www.iana.org/time-zones) database.
  - `strftime` style formatting


[![Build Status](https://travis-ci.org/daurnimator/luatz.png)](https://travis-ci.org/daurnimator/luatz) [![Coverage Status](https://coveralls.io/repos/github/daurnimator/luatz/badge.svg?branch=master)](https://coveralls.io/github/daurnimator/luatz?branch=master)

Supported under Lua 5.1, 5.2, 5.3 and LuaJIT.


## Documentation

Documentation can be found in the `doc` sub-directory.

An online version can be found at https://daurnimator.github.io/luatz/


## Installation

### via [luarocks](https://luarocks.org/modules/daurnimator/luatz)

    luarocks install luatz
