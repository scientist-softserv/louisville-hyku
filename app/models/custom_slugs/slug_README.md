# Custom Slugs

This module contains overrides and modules to implement custom slug behavior for URLs based on Hyrax 2.9.6.

# Assumptions
This implementation assumes the presence of RDF term `:identifier` as the content source for building the slug. The term does not have to be required, but not requiring it may require spec adjustments.

A different term can be substituted by modifying the use of :identifier in CustomSlugs modules `manipulations.rb` and `slug_behavior.rb`, as well as the related spec files.

# Behavior
- Replaces solr id with slug when slug is present
- Adds both fedora id and slug to solr index
- Stores slug in the fedora object
- URL will include slug rather than UUID

# Implementation
- Copy files into models/custom_slugs directory 
- include CustomSlugs::SlugBehavior in work and/or collection model files
- include CustomSlugs::SlugSolrAttributes in solr document file
- include CustomSlugs::SlugIndexer in collection, work, or app indexer files

# Implementing Specs
This implemention includes several shared spec files covering the added modules:
- copy the files from `spec/support/custom_slugs/` directory
- copy `routing/curation_concerns_url_spec.rb`

Make the following spec additions.
- add `include_examples("indexes_custom_slugs")` into appropriate indexer specs.
- add `include_examples("custom_slugs")` into appropriate form specs
- add `include_examples("requires_slugs")` into appropriate form specs
- add `include_examples("object includes slugs")` into appropriate object model specs
- modify object factories to include `identifier { [Faker::Alphanumeric.unique.alphanumeric.to_s] }`

Other specs modifications may be needed, particularly if they refer to a work or collection's `id` if the behavior actually is accessing the solr id. In this case, substitute `to_param`.

# Additional Notes
Existing data would need a migration to save the slug term in Fedora and reindex, but objects should function as before even if there is no migration. If the content source RDF term (:identifier in this repo) already exists in an existing object, editing and saving should initialize and save the slug, and reindex it appropriately.

IIIF manifests in Louisville are handled uniquely for the parent/child works, and required use of CustomSlugs::Manipulations outside of the custom slugs modules. No addition effort was made to refactor and move these into custom_slugs_decorator.rb due the specificity of the use-case.