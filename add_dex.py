import zipfile, os
proj = os.path.dirname(os.path.abspath(__file__))
with zipfile.ZipFile(os.path.join(proj, "build", "base.apk"), "a", zipfile.ZIP_DEFLATED) as z:
    z.write(os.path.join(proj, "build", "classes.dex"), "classes.dex")
print("dex added")