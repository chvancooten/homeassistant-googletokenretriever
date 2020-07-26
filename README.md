# Retrieving Google Home API keys into Home Assistant

This is a very quick and dirty Bash script to automatically pull relevant local authentication tokens for Google Home and load them into Home Assistant on a timer.

Based on great work by [Rithvik Vibhu](https://rithvikvibhu.github.io/GHLocalApi/) on figuring out the API and writing a script to retrieve the Google Master and Access tokens.

## Requirements

- A linux machine with support for cronjobs (does not have to be the Home Assistant host)
- [Get_tokens.py](https://gist.githubusercontent.com/rithvikvibhu/952f83ea656c6782fbd0f1645059055d/raw/00c724829a2786f97fc5251b5aaf998af9a93806/get_tokens.py)
    - The script needs to be configured etiher with your Google credentials (username / (application) password), or with a master key override set. The latter can be done after running the script once.
- The latest release of [grpcurl](https://github.com/fullstorydev/grpcurl/releases)
- Google Foyer [proto files](https://drive.google.com/drive/folders/1RvnN3y-G23pd2SWHmfV_7sef8QU5GNF4) (preserve the folder structure)

## Installation

- Edit the variables in the script as needed, the paths to the downloaded files (see above), and whether or not you want to use health checks via healthchecks.io
    - Add your long-lived API token for the Home Assistant API (generated on your profile)
    - Specify the paths to the files downloaded in the previous step
    - Specify array of devices you want to retrieve the access tokens for (run the grpcurl command from the script manually if you are unsure)
    - Optionally configure (or disable) healthchecks via healthchecks.io
- Verify that the script runs properly and succesfully pushes the data to Home Assistant
- Set the script to run on a Cronjob (tokens are invalidated after 1 hour)

## Home Assistant Integration

The script will push the tokens for the specified devices as *attributes* to an entity `input_text.google_tokens` in Home Assistant. These attributes can now be retrieved via templating within Home Assistant. For example, here is the `command_line` sensor I am using to retrieve the timestamp of the next alarm from my Google Home device.

```
platform: command_line
command: "curl --insecure --header \"cast-local-authorization-token: {{ state_attr('input_text.google_tokens', 'token_my-google-home') }}\" https://my-google-home:8443/setup/assistant/alarms"
name: Next Alarm
value_template: >
  {% set alarms = value_json.alarm|sort(attribute='fire_time') %}
  {% if alarms[0] is defined %}
    {{ alarms[0].fire_time }}
  {% else %}
    None
  {% endif %}
```

If health checks are used, the [healthchecksio](https://github.com/custom-components/healthchecksio) custom component could be used to monitor the status of the script from within Home Assistant.
