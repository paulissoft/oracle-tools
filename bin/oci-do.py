#!/usr/bin/env python
# standard Python modules
from typing import Tuple, Optional, Union, Any
import os
from dotenv import load_dotenv
import io
import logging
import traceback

# https://realpython.com/command-line-interfaces-python-argparse/
import argparse
from pathlib import Path
import inspect

import oci

# logging.basicConfig(level=logging.INFO, format='%(levelname)-8s  %(asctime)s  %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logging.basicConfig(
    level=logging.DEBUG if os.getenv("DEBUG") else logging.INFO,
    format="%(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def inspect_object(name: str, obj: Any) -> None:
    logger.info(f"object {name} type: {type(obj)}; repr: {repr(obj)}")
    for member, value in inspect.getmembers(obj):
        if not member.startswith("_"):
            logger.info(f"{member}: {value}")

def main():
    load_dotenv()

    parser = argparse.ArgumentParser(
        description="Show ocifs.OCIFileSystem commands.",
        add_help=True,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-b", "--bucket-name",
#        required=True,
        help="The bucket name",
        default=os.getenv('BUCKET_NAME')
    )
    parser.add_argument(
        "-c", "--config",
        help="read the OCI config file",
        default=f"{os.getenv('HOME')}/.oci/config",
    )
    parser.add_argument(
        "-d", "--debug",
        action="store_true",
        help="debug mode")
    parser.add_argument(
        "-n", "--namespace",
#        required=True,
        help="The bucket namespace",
        default=os.getenv('NAMESPACE')
    )
    parser.add_argument(
        "-o", "--operation",
        choices=['list', 'download'],
#        required=True,
        help="The operation to execute on the objects in the source folder for this bucket and namespace",
        default="list"
    )
    parser.add_argument(
        "-p", "--profile",
        help="Use this OCI profile",
        default=os.getenv("PROFILE") if os.getenv("PROFILE") else "DEFAULT"
    )
    parser.add_argument(
        "--oci-prefix",
        help="Prefix for OCI objects",
        default=""
    )
    parser.add_argument(
        "--local-folder",
        help="Local folder to work on",
        default="."
    )

    args = parser.parse_args()
    if args.debug:
        logger.setLevel(logging.DEBUG)

    assert args.config, "--config option should be set"
    assert args.profile, "--profile option should be set"

    logger.debug(f"Config: {args.config}")
    logger.debug(f"Profile: {args.profile}")
    logger.debug(f"Bucket name: {args.bucket_name}")
    logger.debug(f"Namespace: {args.namespace}")
    logger.debug(f"OCI prefix: {args.oci_prefix}")
    logger.debug(f"Local folder: {args.local_folder}")

    config = oci.config.from_file(file_location=args.config, profile_name=args.profile)
    object_storage = oci.object_storage.ObjectStorageClient(config)
    files = object_storage.list_objects(namespace_name=args.namespace, bucket_name=args.bucket_name, prefix=args.oci_prefix)

    for file in files.data.objects:
        print(f"file: {file.name}")

    if args.operation == 'download':
        confirm = input('Are you sure to download these files? [N] : ')
        if confirm.lower() == 'y':
            for file in files.data.objects:
                object = object_storage.get_object(args.namespace, args.bucket_name, file.name)
                output_file = f"{args.local_folder}/{file.name}"
                print(f"downloading {file.name} to {output_file}")
                with open(output_file, 'wb') as f:
                    for chunk in object.data.raw.stream(1024 * 1024, decode_content=False):
                        f.write(chunk)
        

if __name__ == "__main__":
    main()
