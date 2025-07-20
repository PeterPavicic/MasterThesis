import os
import requests
import json
import csv


# TODO: Finish writing this

# Collection of yes tokens
TOKEN_DICTIONARY = {
        "Trump": "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "Biden": "88027839609243624193415614179328679602612916497045596227438675518749602824929",
        "RFKJr": "75551890681049796405776295654438099776333571510662809052054780589218524237663",
        "Harris": "69236923620077691027083946871148646972011131466059644796654161903044970987404",
        "Kanye": "48285207411891694847413807268670593735244327770017422161322089036370055854362",
        "TrumpPopularVote": "42699080635179861375280720242213672850141860123562672932351602811041149946128",
        "KamalaPopularVote": "21271000291843361249209065706097167029083067325856089903026951915683588703117",
        "WisconsinDemocratWin": "7374237615890526880478224649885278725219793468355446734533315746155037370158",
        "WisconsinRepublicanWin": "8506489790932625039746959405160059426243994232527626857062384302531008283468",
        "NevadaDemocratWin": "23452090462928163585257733383879365528898800849298930788345778676568194082451",
        "NevadaRepublicanWin": "22811156622772246927379314532791131581149105511872861362055243423465705837015",
        "PennsylvaniaDemocratWin": "96404870680531697292788145333705429762370661278621665925868256650124167091957",
        "PennsylvaniaRepublicanWin": "75951511934878014812323289513632732239356274541965522720897159608390126393735",
        "MichiganDemocratWin": "67987395510317512691808452556846479650140447681921231570668523107587946046381",
        "MichiganRepublicanWin": "105184348976114274990683066782141725521410345945023353024053078695238621958578",
        "NorthCarolinaDemocratWin": "100038420537482572525556691531865148324318723289388392794253042393988283565188",
        "NorthCarolinaRepublicanWin": "25474014705297439146444713942104010240322868585952420291288261803408266882449",
        "ArizonaDemocratWin": "77888176678720060596595785704561867851638990901352765132303721825934989281472",
        "ArizonaRepublicanWin": "64972410044896218211047269420581789917870192018252181026286744947120013986348",
        "GeorgiaDemocratWin": "71266923597682191255015907302921683041435419763570474059916757401212183782544",
        "GeorgiaRepublicanWin": "10874846387975190407444713373765853114527145924436779240006871443341352408992"}


def download_json(url, output_file):
    """
    Downloads a JSON file from the given URL and saves it to the specified output file.

    Args:
        url (str): The URL to fetch the JSON data from.
        output_file (str): The path to the output file where JSON will be saved.
    """
    try:
        # Send a GET request to the URL
        response = requests.get(url)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx and 5xx)

        # Ensure the directory exists
        os.makedirs(os.path.dirname(output_file), exist_ok=True)

        # Write the JSON data to the file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(response.text)

        print(f"JSON data has been saved to {output_file}")

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from {url}: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


def json_to_csv(json_file, csv_file):
    """
    Converts a JSON file to a CSV file with columns "t" and "p".

    Args:
        json_file (str): Path to the JSON file.
        csv_file (str): Path to the output CSV file.
    """
    try:
        # Read the JSON file
        with open(json_file, 'r') as jf:
            data = json.load(jf)

        # Open the CSV file for writing
        with open(csv_file, 'w', newline='') as cf:
            writer = csv.writer(cf)

            # Write the header
            writer.writerow(["timestamp", "price"])

            # Write the data
            for entry in data["history"]:
                writer.writerow([entry["t"], entry["p"]])

        print(f"CSV file successfully written to {csv_file}")

    except Exception as e:
        print(f"An error occurred: {e}")




# Example usage
if __name__ == "__main__":

    tokens_to_get = ["Trump", "Biden", "Harris", "RFKJr", "Kanye"]

    urlStart = "https://clob.polymarket.com/prices-history?market="
    urlEnd = "&fidelity=1&startTs=1704373200"
    outputFileStart = "./price_data/"

    outputFileEnd = "_full_minute_data.json"

    for token in tokens_to_get:
        clob_id = TOKEN_DICTIONARY[token]
        url = urlStart + clob_id + urlEnd
        jsonFile = outputFileStart + token.lower() + outputFileEnd
        download_json(url, jsonFile)
        csvFile = jsonFile[:-4] + "csv"
        json_to_csv(jsonFile, csvFile)
