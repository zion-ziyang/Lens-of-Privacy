import pandas as pd
import numpy as np
import argparse
import json
import sys
import os

def convert_numpy_types(obj):
    if isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, dict):
        return {k: convert_numpy_types(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_numpy_types(item) for item in obj]
    else:
        return obj

def unpack_and_save(df, output_json_path, output_image_dir):
    print(f"\nStarting unpacking and saving process...")
    os.makedirs(output_image_dir, exist_ok=True)

    final_records = []
    images_saved_count = 0
    images_skipped_count = 0
    records_processed_count = 0

    for index, row in df.iterrows():
        records_processed_count += 1
        try:
            output_record = row.to_dict()
            image_data = output_record.get('image')

            if isinstance(image_data, dict) and 'bytes' in image_data and 'path' in image_data:
                image_bytes = image_data.get('bytes')
                image_filename = image_data.get('path')

                if isinstance(image_bytes, bytes) and isinstance(image_filename, str) and image_filename.strip():
                    save_path = os.path.join(output_image_dir, image_filename)
                    try:
                        with open(save_path, 'wb') as img_file:
                            img_file.write(image_bytes)
                        output_record['image'] = image_filename
                        images_saved_count += 1
                    except IOError as e:
                        print(f"Warning (Row {index}): Could not save image {image_filename} to {save_path}. Error: {e}. Setting image field to None.")
                        output_record['image'] = None # Indicate save error
                        images_skipped_count += 1
                    except Exception as e:
                         print(f"Warning (Row {index}): An unexpected error occurred saving image {image_filename} to {save_path}. Error: {e}. Setting image field to None.")
                         output_record['image'] = None
                         images_skipped_count += 1
                else:
                    print(f"Warning (Row {index}): Invalid data types found within image dict (bytes: {type(image_bytes)}, path: {type(image_filename)}). Setting image field to None.")
                    output_record['image'] = None
                    images_skipped_count += 1
            else:
                 if image_data is not None:
                     print(f"Warning (Row {index}): Image data is not in the expected format (type: {type(image_data)}). Leaving image field as is or setting to None.")
                 output_record['image'] = None
                 images_skipped_count += 1

            final_records.append(output_record)

        except Exception as e:
             print(f"Error processing row {index}: {e}. Skipping row.")

    print(f"\nSaving unpacked metadata to {output_json_path}...")
    try:
        final_records_serializable = convert_numpy_types(final_records)
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(final_records_serializable, f, indent=2, ensure_ascii=False)
        print("JSON metadata save complete.")
    except IOError as e:
        print(f"Error: Could not write JSON file {output_json_path}. Error: {e}")
    except TypeError as e:
        print(f"Error: Could not serialize data to JSON. Check for non-standard data types. Error: {e}")

    print(f"\n--- Unpacking Summary ---")
    print(f"Total records processed: {records_processed_count}")
    print(f"Records successfully added to JSON: {len(final_records)}")
    print(f"Images saved to '{output_image_dir}': {images_saved_count}")
    print(f"Images skipped (due to missing data or errors): {images_skipped_count}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Unpack data from a Parquet file, saving images and metadata separately.")
    parser.add_argument("parquet_file", 
                        help="Path to the input Parquet file containing packed data.")
    parser.add_argument("-i", "--output-image-dir", 
                        default="images",
                        help="Directory to save the unpacked image files (default: images)")
    parser.add_argument("-j", "--output-json", 
                        default="data.json",
                        help="Path to save the unpacked JSON metadata file (default: data.json)")
    args = parser.parse_args()

    print(f"Input Parquet file: {args.parquet_file}")
    print(f"Output Image directory: {args.output_image_dir}")
    print(f"Output JSON file: {args.output_json}")

    try:
        df = pd.read_parquet(args.parquet_file)
        print(f"\nSuccessfully read {len(df)} records from {args.parquet_file}")
    except FileNotFoundError:
        print(f"Error: Input Parquet file not found at {args.parquet_file}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading Parquet file {args.parquet_file}: {e}")
        sys.exit(1)

    if not df.empty:
        unpack_and_save(df, output_json_path=args.output_json, output_image_dir=args.output_image_dir)
    else:
        print("\nExiting: DataFrame is empty after reading the parquet file.")