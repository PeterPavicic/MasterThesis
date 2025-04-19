#!./venv/bin/python


if __name__ == "__main__":
    import argparse
    from fetching_data import jsons_to_csv

    parser = argparse.ArgumentParser(
        description="Combine multiple JSON files into a single CSV."
    )
    parser.add_argument(
        "input_dir",
        help="Path to the directory containing .json files"
    )
    parser.add_argument(
        "output_csv",
        help="Path where the combined CSV should be written"
    )
    args = parser.parse_args()

    print("Starting JSON --> CSV conversion...")
    jsons_to_csv(args.input_dir, args.output_csv)
