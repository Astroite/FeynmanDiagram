class_name ReverseEdgeCommand
extends Command

# Flip a fermion line's direction: swap its two half-edges (and reverse the stored
# curve). The geometry is unchanged; only the fermion arrow — derived from which end is
# `a` — turns around. Reversing is its own inverse, so do() and undo() are identical.

var _model: GraphModel = null
var _edge: GraphEdge = null


func configure(model: GraphModel, edge: GraphEdge) -> ReverseEdgeCommand:
	label = &"reverse_edge"
	_model = model
	_edge = edge
	return self


func do() -> bool:
	return _model != null and _edge != null and _model.reverse_edge(_edge)


func undo() -> bool:
	return _model != null and _edge != null and _model.reverse_edge(_edge)
