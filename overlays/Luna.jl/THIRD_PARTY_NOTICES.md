# Upstream attribution and downloaded dependencies

Project: Luna.jl
Official source: https://github.com/LupoLab/Luna.jl

Opt_Package downloads the exact upstream source commit stated in manifests/native.json. Upstream copyright and license files remain in that source tree. Third-party executables, SDKs, compiled libraries, environments and caches are not distributed in this overlay; installation downloads them from their official publishers and checks the pinned digests or package lock checksums.

The upstream project and each dependency keep their own licenses. The Opt_Package repository license does not replace upstream licensing. Downloaded runtime/SDK license notices remain with those downloaded files. Modified reZonator source and its source-fixes.patch retain the upstream GPL v3 license and copyright headers, with the full upstream LICENSE in that overlay.

Package locks and installer scripts identify exact versions and artifact origins. A local source build does not itself grant permission to redistribute its resulting third-party runtime bundle.
