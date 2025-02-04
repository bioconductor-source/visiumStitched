% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build_spe.R
\name{build_spe}
\alias{build_spe}
\title{Build stitched \code{SpatialExperiment}}
\usage{
build_spe(
  sample_info,
  coords_dir,
  count_type = "sparse",
  reference_gtf = NULL,
  gtf_cols = c("source", "type", "gene_id", "gene_version", "gene_name", "gene_type")
)
}
\arguments{
\item{sample_info}{A \code{data.frame()} with columns \code{capture_area},
\code{group}, \code{fiji_xml_path}, \code{fiji_image_path},
\code{spaceranger_dir}, \code{intra_group_scalar}, and
\code{group_hires_scalef}. The last two are made by \code{rescale_fiji_inputs()}.}

\item{coords_dir}{A \code{character(1)} vector giving the directory
containing sample directories each with \code{tissue_positions.csv},
\code{scalefactors_json.json}, and \code{tissue_lowres_image.png} files
produced from refinement with \link[=prep_fiji_coords]{prep_fiji_coords()}
and related functions.}

\item{count_type}{A \code{character(1)} vector passed to \code{type} from
\code{SpatialExperiment::read10xVisium}, defaulting to "sparse".}

\item{reference_gtf}{Passed to \code{\link[spatialLIBD:read10xVisiumWrapper]{spatialLIBD::read10xVisiumWrapper()}}. If
working on the same system where SpaceRanger was run, the GTF will be
automatically found; otherwise a \code{character(1)} path may be supplied,
pointing to a GTF file of gene annotation to populate \code{rowData()} with.}

\item{gtf_cols}{Passed to \code{\link[spatialLIBD:read10xVisiumWrapper]{spatialLIBD::read10xVisiumWrapper()}}. Columns
in the reference GTF to extract and populate \code{rowData()}.}
}
\value{
A \link[SpatialExperiment:SpatialExperiment]{SpatialExperiment-class}
object with one sample per group specified in \code{sample_info} using
transformed pixel and array coordinates (including  in the
\code{spatialCoords()}).
}
\description{
First, read in capture-area-level \code{SpaceRanger}
\url{https://www.10xgenomics.com/support/software/space-ranger/latest/analysis/running-pipelines/space-ranger-count}
outputs. Then, overwrite
spatial coordinates and images to represent group-level samples using
\code{sample_info$group} (though keep original coordinates in
\code{colData} columns ending with the suffix \code{"_original"}). Next, add info
about overlaps (via \code{spe$exclude_overlapping} and
\code{spe$overlap_key}).
Ultimately, return a
\link[SpatialExperiment:SpatialExperiment]{SpatialExperiment-class} ready
for visualization or downstream analysis.
}
\examples{
########################################################################
#   Prepare sample_info
########################################################################

sample_info <- dplyr::tibble(
    group = "Br2719",
    capture_area = c("V13B23-283_A1", "V13B23-283_C1", "V13B23-283_D1")
)
#   Add 'spaceranger_dir' column
sr_dir <- tempdir()
temp <- unzip(
    spatialLIBD::fetch_data("visiumStitched_brain_spaceranger"),
    exdir = sr_dir
)
sample_info$spaceranger_dir <- file.path(
    sr_dir, sample_info$capture_area, "outs", "spatial"
)

#   Add Fiji-output-related columns
fiji_dir <- tempdir()
temp <- unzip(
    spatialLIBD::fetch_data("visiumStitched_brain_Fiji_out"),
    exdir = fiji_dir
)
sample_info$fiji_xml_path <- temp[grep("xml$", temp)]
sample_info$fiji_image_path <- temp[grep("png$", temp)]

## Re-size images and add more information to the sample_info
sample_info <- rescale_fiji_inputs(sample_info, out_dir = tempdir())

## Preparing Fiji coordinates and images for build_spe()
spe_input_dir <- tempdir()
prep_fiji_coords(sample_info, out_dir = spe_input_dir)
prep_fiji_image(sample_info, out_dir = spe_input_dir)

########################################################################
#   Build the SpatialExperiment
########################################################################

#    Since we don't have access to the original GTF used to run SpaceRanger,
#    we must explicitly supply our own GTF to build_spe(). We use
#    GENCODE release 32, intended to be quite close to the actual GTF used,
#    which is available from:
#    https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz
bfc <- BiocFileCache::BiocFileCache()
gtf_cache <- BiocFileCache::bfcrpath(
    bfc,
    paste0(
        "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/",
        "release_32/gencode.v32.annotation.gtf.gz"
    )
)

## Now we can build the stitched SpatialExperiment object
spe <- build_spe(
    sample_info,
    coords_dir = spe_input_dir, reference_gtf = gtf_cache
)

## Let's explore the stitched SpatialExperiment object
spe
}
\author{
Nicholas J. Eagles
}
