#!/usr/bin/env python
# standard Python modules
from typing import Tuple, Optional, Union, Any
import os
import io
import logging
import traceback

# https://realpython.com/command-line-interfaces-python-argparse/
import argparse
from pathlib import Path
import inspect

from ocifs import OCIFileSystem
from fsspec.core import OpenFile


# Some types
File = Union[OpenFile]
Stream = Union[io.BytesIO, io.BufferedReader]

# The OCI file system is the default
fs = None


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
    global fs

    parser = argparse.ArgumentParser(
        description="Show ocifs.OCIFileSystem commands.",
        add_help=True,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-b", "--bucket-name",
        required=True,
        help="The bucket name"
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
        required=True,
        help="The bucket namespace"
    )
    parser.add_argument(
        "-o", "--object-name",
        required=True,
        help="The object name"
    )
    parser.add_argument(
        "-p", "--profile",
        help="Use this OCI profile",
        default="DEFAULT"
    )

    args, ocifs_command = parser.parse_known_args()
    if args.debug:
        logger.setLevel(logging.DEBUG)
    
    logger.info(f"Bucket name: {args.bucket_name}")
    logger.info(f"Namespace: {args.namespace}")
    logger.info(f"Object name: {args.object_name}")
    logger.info(f"ocifs command: {ocifs_command}")

    assert args.config, "--config option should be set"
    assert args.profile, "--profile option should be set"
    fs = OCIFileSystem(config=args.config, profile=args.profile)
    logging.getLogger("ocifs").setLevel(logging.ERROR)
    file: Union[Path, str] = f"oci://{args.bucket_name}@{args.namespace}/{args.object_name}"

    logger.info(f"ocifs file: {file}")

    # https://ocifs.readthedocs.io/en/latest/unix-operations.html

    if fs.isfile(f"{file}"):
        logger.info("It is a file")
    else:
        logger.info("It is NOT a file")

    if fs.isdir(f"{file}"):
        logger.info("It is a directory")
        for entry in fs.ls(f"{file}"):
            logger.info(f"file: {entry}")
            
    else:
        logger.info("It is NOT a directory")

    # eval(f"{ocifs_command}")

if __name__ == "__main__":
    main()
