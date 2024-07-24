"""Compress

I ran the benchmarks before the Tenpy commit 801dc101c9c6fdcfe283d6fb730ed6fc0ab8a42e
hence the output files were significantly larger than necessary.
This script converts the lists in the stats and saves them again,
as if they were produces after this commit.
I called it as
``python compress_h5_stats.py $(find . -name "*.h5")``,
checked that the files went from ~30MB to <1MB with
``ls -l $(find . -name "*.h5")``
and then cleaned the backups as
``find . -name "*.backup.h5" -delete``
"""


import tenpy
from tenpy.algorithms.truncation import TruncationError
import numpy as np
import os


def compress_stats(filename):
    assert filename.endswith('.h5')
    filename_bk = filename[:-3] + '.backup.h5'
    print(f"rename {filename} -> {filename_bk} and compress")
    os.rename(filename, filename_bk)
    results = tenpy.load(filename_bk)
    for key in ['measurements', 'sweep_stats', 'update_stats']:
        if key in results:
            # try to convert lists into numpy arrays to store more compactly
            data = results[key].copy()
            for k, v in results[key].items():
                if isinstance(v, list):
                    if len(v) > 0 and isinstance(v[0], TruncationError):
                        # special handling for TruncationError: convert to _eps and _ov lists
                        try:
                            v_err = [err.eps for err in v]
                            v_ov = [err.ov for err in v]
                            del data[k]
                            data[k + "_eps"] = np.array(v_err)
                            data[k + "_ov"] = np.array(v_ov)
                        except:
                            pass
                        continue
                    try:
                        v = np.array(v)
                    except:
                        continue
                    if v.dtype != np.dtype(object):
                        data[k] = v
            results[key] = data
    tenpy.save(results, filename)


if __name__ == "__main__":
    import sys
    for fn in sys.argv[1:]:
        compress_stats(fn)
