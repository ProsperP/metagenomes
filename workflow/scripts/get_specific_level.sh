#!/bin/bash


INPUT=$1
LEVEL=$2
OUTPUT=$3


case ${LEVEL} in
    phylum)
        prefix="p__"
        next_prefix="c__"
        ;;
    class)
        prefix="c__"
        next_prefix="o__"
        ;;
    order)
        prefix="o__"
        next_prefix="f__"
        ;;
    family)
        prefix="f__"
        next_prefix="g__"
        ;;
    genus)
        prefix="g__"
        next_prefix="s__"
        ;;
    species)
        prefix="s__"
        next_prefix="t__"
        ;;
    strain)
        prefix="t__"
        ;;
    *)
        echo "Level should be one of the phylum, class, order, family, genus, species, strain."
esac

if [[ ${LEVEL} != "strain" ]]; then
    grep -E "${prefix}|clade" ${INPUT} \
        | grep -v "${next_prefix}" \
        | sed "s/^.*|//g" \
        > ${OUTPUT}
else
    grep -E "${prefix}|clade" ${INPUT} \
        | sed -e "s/^.*|s__/t__/g" -e "s/|t__/ (/" -e '2,$s/\t/)\t/' \
        > ${OUTPUT}
fi
