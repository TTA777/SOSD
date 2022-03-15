import numpy as np
import struct
import os
import sys


def print_file(fn):
    print("Reading data ", fn)
    d = np.fromfile("data/" + fn + "_800M_uint64", dtype=np.uint64)[1:]
    print("saving file")
    with open("data/" + fn + "_800M_uint64_human_readable", "w") as f:
        for x in d:
            print("{}".format(x), file=f)

print_file("books")
print_file("osm_cellids")
    
