import sys
from os import path
import pandas as pd
import argparse
from shutil import copyfile


# pd.set_option('display.max_columns', None)
# pd.set_option('display.max_rows', None)
merge_path: str = "/tmp/epg_merge.csv"
parser = argparse.ArgumentParser(description="Flip a switch by setting a flag")
parser.add_argument("--path", "-p", help="Fill from git history", action="store", dest="file_path")
parser.add_argument(
    "--stats",
    "-s",
    help="Calculate statistics",
    action="store_true",
    default=False,
    dest="is_stats",
)


def fill_from_git_history(file_path: str) -> None:
    if path.exists(merge_path):
        df_merge = pd.read_csv(merge_path)
    else:
        copyfile(file_path, merge_path)
        sys.exit(0)
    df = pd.read_csv(file_path)
    df_res = pd.concat([df_merge, df], ignore_index=True)
    df_res.set_index(["date"], inplace=True)
    df_res.to_csv(merge_path)
    print(df_res.shape)
    print(df.head())


def stats() -> None:

    df: pd.DataFrame = pd.read_csv(merge_path)
    df.reset_index().set_index(["date"], inplace=True)
    df["total"] = df.groupby("id").date.transform("count")
    df["missed_count"] = df[df.missed == True].missed.groupby(df.id).transform("count")
    df["missed_count"] = df.missed_count.fillna(value=0)
    df["icon"] = df.icon.fillna(value="")
    df["missed_percent"] = (df.missed_count / df.total) * 100
    df.drop(["date"], axis=1, inplace=True)
    df.drop_duplicates(subset="id", keep="first", inplace=True)
    df.sort_values(by="missed_percent", ascending=False, inplace=True)
    df.reset_index(inplace=True)
    df.drop("index", axis=1, inplace=True)
    print(df.shape)
    # print(df[(df.missed_count > 0) & (df.missed_count < 9)].head(20))
    print(df.head(20))
    df.to_csv("out/epg_stats.csv")


if __name__ == "__main__":
    args = parser.parse_args()
    if args.is_stats:
        stats()
    elif args.file_path:
        fill_from_git_history(args.file_path)

    sys.exit(0)
