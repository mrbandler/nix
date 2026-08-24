# Typed host contract + fleet-wide activations.
# - `includes` here are applied to EVERY host: hosts only include what makes
#   them different; `core` is what makes them the same.
# - Typed host facts (e.g. gpu) get declared here as options when a fact gains
#   multiple consumer aspects.
{ den, ... }:
{
  den.schema.host.includes = [ den.aspects.core ];
}
