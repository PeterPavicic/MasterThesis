from pathlib import Path
import os
import requests
import json

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


def download_events(queries: dict | list[dict], output_dir):
    if isinstance(queries, dict):
        queries = [queries]

    gammaURL = "https://gamma-api.polymarket.com/events"

    for querystring in queries:
        try:
            response = requests.request("GET", gammaURL, params=querystring)
            print(response.text)
            data = response.json()
            output_path = os.path.join(output_dir, f"{data.get("ticker")}.json")

            with open(output_path, "w") as file:
                json.dump(data, file, indent=2)
            print(f"Saved {data.get("title")} events to {output_path}")

        except requests.RequestException as e:
            print(f"Network/HTTP error: {e}")
            break

        except json.JSONDecodeError:
            print(f"Failed to parse JSON response.")
            break

        except Exception as e:
            print(f"An error occurred: {e}")
            break

    print("Saved all queries to output paths")


if __name__ == "__main__":
    here = Path(__file__)
    slug_file = os.path.join(here.parent.parent, "Markets/all_fomc_slugs.txt")
    print(slug_file)


    gammaURL = "https://gamma-api.polymarket.com/events"
    with open(slug_file, 'r') as file:
        for line in file:
            slug = line[:-1]
            querystring = {"slug":slug}
            response = requests.request("GET", gammaURL, params=querystring)
            print(response.text)

