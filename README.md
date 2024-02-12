# @FundaGold Telegram bot 🤖

<img src="https://blog.funda.nl/content/images/2021/04/logo.svg" alt="Alternative Text" width="300" height="200"/>

[![Publish Docker Image](https://github.com/dimohamdy/FundaGold/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/dimohamdy/FundaGold/actions/workflows/docker-publish.yml)
[![Run Terraform AWS](https://github.com/dimohamdy/FundaGold/actions/workflows/aws_terraform.yml/badge.svg)](https://github.com/dimohamdy/FundaGold/actions/workflows/aws_terraform.yml)

## Overview
The @FundaGold bot is a specialized Telegram bot designed to assist users in finding rental apartments across various websites. By sending a JSON-formatted message to the bot, users can specify their preferences for a rental apartment, and the bot will aggregate options from multiple supported websites.

## JSON Request Format
Users need to send a message in the following JSON format:

```json
{
    "selectedAreas": [
        "Amsterdam", "Utrecht", "Amersfoort", "Nieuwegein", "Houten", "Bussum"
    ],
    "price": "1500",
    "floorArea": "100",
    "bedrooms": "2"
}
```


## Fields Explanation
- `selectedAreas`: List of areas where the user wants to find an apartment.
- `price`: Maximum rental price in Euros.
- `floorArea`: Minimum area of the apartment in square meters.
- `bedrooms`: Number of bedrooms required.

## Supported Websites
The bot currently aggregates data from the following websites, with more to be added:

- **Funda**: [www.funda.nl](https://funda.nl)
- **Ikwilhuren**: [www.ikwilhuren.nu](https://ikwilhuren.nu)
- **Pararius**: [www.pararius.nl](http://www.pararius.nl)
- **Vesteda**: [www.vesteda.com](http://www.vesteda.com)
- **Huurwoningen**: [www.huurwoningen.nl](http://www.huurwoningen.nl)
- **Wonenbijbouwinvest**: [www.wonenbijbouwinvest.nl](http://www.wonenbijbouwinvest.nl)

## Usage Instructions
1. Open Telegram and search for the @FundaGold bot.
2. Send your apartment preferences in the JSON format provided above.
3. The bot will process your request and return a list of available apartments matching your criteria from the supported websites.

## TODO:
- [x] Deploy bot on AWS for 24/7 availability.
- [x] Setup AWS infrastructure using Terraform.
- [ ] Write integration tests and monitor code coverage.
- [ ] Implement NLP-based search.
- [ ] Handle errors and edge cases gracefully.
- [ ] Enhance user experience with interactive responses.
- [ ] Add support for additional languages.

---

For any queries or support, please contact me at dimo.hamdy@gmail.com.
