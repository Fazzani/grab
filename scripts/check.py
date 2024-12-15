# type: ignore
import datetime
import glob
import logging
import os
import sys
import xml.etree.ElementTree as ET
from typing import List, Tuple

import pandas as pd

LOGLEVEL = os.environ.get("LOGLEVEL", "INFO").upper()
logging.basicConfig(level=LOGLEVEL)


def check(file_path: str) -> Tuple[List[any], List[str]]:
    tree = ET.parse(file_path)
    root = tree.getroot()

    df_cols: List[str] = ["start", "channel", "title"]
    df: pd.DataFrame = pd.DataFrame(columns=df_cols)

    all_channels: List[any] = list(
        map(
            lambda c: {
                "id": c.get("id"),
                "icon": c.find("icon").get("src").split("|")[0] if c.find("icon") is not None else "",
                "site": c.find("url").text if c.find("url") else "",
                "country": c.get("id").split(".")[-1] if c.get("id") is not None and "." in c.get("id") else "",
            },
            root.findall("channel"),
        )
    )

    logging.info("grab all programs...")

    progs = list(
        map(
            lambda i: {
                "start": i.get("start"),
                "channel": i.get("channel"),
                "title": i.find("./title").text,
            },
            root.findall("programme"),
        )
    )
    df = pd.concat(
        [df, pd.DataFrame(progs)],
        ignore_index=True,
    )

    df.set_index("start", inplace=True)
    df = df.set_index(pd.to_datetime(df.index))
    df.index = pd.to_datetime(df.index, utc=True)
    res: pd.DataFrame = df[df.index.to_pydatetime() > (datetime.datetime.now(datetime.timezone.utc) - pd.Timedelta(days=1))]
    count = res.groupby(["channel"], as_index=False).count()
    logging.debug(f"count: {count}")

    unique_all_channels = pd.DataFrame(all_channels).drop_duplicates(subset="id", keep="first").to_dict("records")

    channels_with_no_prog = [x for x in set(map(lambda c: c["id"], unique_all_channels)) if x not in set(res["channel"].unique().tolist())]

    return (unique_all_channels, channels_with_no_prog)


if __name__ == "__main__":
    all: List[dict] = []
    missed: List[str] = []
    logging.debug(f"{datetime.datetime.today()}")
    try:
        for file_path in glob.glob(sys.argv[1] + "/*.xml"):
            logging.info(f"processing file {file_path}")
            all_ch, missed_ch = check(file_path)
            all = [*all, *all_ch]
            missed = [*missed, *missed_ch]

        df: pd.DataFrame = pd.DataFrame(all, columns=["id", "icon", "site", "country"])
        duplicated_ignore_case_df = df.groupby(df.id.str.lower()).filter(lambda x: (len(x) > 1))
        logging.info(duplicated_ignore_case_df.head(10))

        df["date"] = datetime.datetime.today()
        df.set_index("date", inplace=True)
        df["missed"] = df["id"].apply(lambda row: row in missed)

        logging.debug(df.head(10))
        logging.debug(f"all: {all}")
        logging.debug(f"with no progs: {missed}")
        logging.info(f"Total count: {len(all)} missed count: {len(missed)}")
        logging.info(f"Completeness {100-(len(missed)/len(all)*100):3.2f}%")

        df.to_csv(
            os.path.join(sys.argv[1], "out", "epg.csv"),
            encoding="utf-8",
            date_format="%Y%m%d",
        )

    except Exception as ex:
        logging.error("Unexpected error:", ex)
        sys.exit(1)
