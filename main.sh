#!/bin/bash
#Get the location information
locationData=$(curl -s ipinfo.io)

city=$(echo $locationData | jq '.city' | awk 'gsub(/"/,"")')
state=$(echo $locationData | jq '.region' | awk 'gsub(/"/,"")')

lat=$(echo $locationData | jq '.loc' | awk -F ',' '{print $1}' | awk 'gsub(/"/,"")')
long=$(echo $locationData | jq '.loc' | awk -F ',' '{print $2}' | awk 'gsub(/"/,"")')

#Get the Data
data=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long&hourly=precipitation_probability&current=temperature_2m&timezone=America%2FChicago&forecast_days=3&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch")

#Lets Get the Time
time=$(echo $data | jq '.current.time' | awk -F 'T' '{print $2}'| awk 'gsub(/"/,"")')

timeHour=$(echo $time | awk -F ':' '{print $1}')

if [ "$timeHour" > "12" ]; then
	time="$time PM"
else
	time="$time AM"
fi

#Lets get the temperature
temperature=$(echo $data | jq '.current.temperature_2m')

#3 hour precip chance (Probably Sketchy to do it this way )
preciphOne=$(echo $data | jq ".hourly.precipitation_probability[$timeHour]")
preciphTwo=$(echo $data | jq ".hourly.precipitation_probability[$((timeHour+1))]")
preciphThree=$(echo $data | jq ".hourly.precipitation_probability[$((timeHour+3))]")

threeHourAverage=$((preciphOne+preciphTwo+preciphThree))
threeHourAverage=$(($threeHourAverage/3))

#final weather statement
finalStatement="📍 $city, $state | ⌚ $time"

# Set the conditional for rain
if [ "$threeHourAverage" -ge 50 ]; then
	finalStatement="$finalStatement | ⛈️ $threeHourAverage %"
fi
if [ "$threeHourAverage" -lt 50 ]; then
	finalStatement="$finalStatement | 🌤️ $threeHourAverage %"
fi

# Set the conditional for temperature
if awk "BEGIN {exit !($temperature>75)}"; then
	finalStatement="$finalStatement | 🔥 $temperature "
else
	finalStatement="$finalStatement | 🧊 $temperature "
fi

#Do the final thing
echo $finalStatement
