# ``OpenWeather``

Tiny framework to get weather information using the openweathermap.org API

## Overview

``OpenWeatherController`` is a global class with only static functions

``OpenWeatherController/setup(appId:)`` must be called before any other functions

Call ``OpenWeatherController/requestCities(withName:handler:)`` to get a list of cities matching a city name

To get all weather updates for a city from its coordinates, register an ``OpenWeatherObserver`` with ``OpenWeatherController/addObserver(_:for:)``.
Call ``OpenWeatherController/getWeather(for:)`` to get the lastest weather information for a city from its coordinates.
The observer callback function is called automatically every 5 minures

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
