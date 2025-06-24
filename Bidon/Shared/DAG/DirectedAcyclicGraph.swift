//
//  AcyclicGraph.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


struct DirectedAcyclicGraph<Node: Equatable & CustomStringConvertible> {
    enum GraphError: Error {
        case nodeNotFound
        case nodeExists
        case cycleDependency
    }

    private var nodes: [Node]
    private var edges: [Int: Set<Int>]

    var root: [Node] {
        return edges
            .reduce(Array(edges.keys)) { result, edge in
                return result.filter { !edge.value.contains($0) }
            }
            .compactMap { nodes[$0] }
    }

    var width: Int {
        edges.reduce(0) { max($0, $1.value.count) }
    }

    init(nodes: [Node] = []) {
        self.nodes = nodes
        self.edges = nodes
            .enumerated()
            .map { $0.offset }
            .reduce([:]) { edges, offset in
                var edges = edges
                edges[offset] = Set()
                return edges
            }
    }

    mutating func add(node: Node) throws {
        guard !nodes.contains(node) else { return }
        nodes.append(node)
        edges[nodes.count - 1] = Set()
    }

    mutating func addEdge(from fromNode: Node, to toNode: Node) throws {
        guard
            let fromIndex = nodes.firstIndex(of: fromNode),
            let toIndex = nodes.firstIndex(of: toNode)
        else {
            throw GraphError.nodeNotFound
        }

        var toEdges = edges[fromIndex]
        toEdges?.insert(toIndex)
        edges[fromIndex] = toEdges
    }

    func seeds(of node: Node) -> [Node] {
        guard
            let idx = nodes.firstIndex(of: node),
            let seeds = edges[idx]
        else { return [] }
        return seeds.compactMap { nodes[$0] }
    }
}


extension DirectedAcyclicGraph where Node == Operation {
    func operations() -> [Operation] {
        return root.reduce([]) {
            traverse(operation: $1, previous: $0)
        }
    }

    private func traverse(
        operation: Operation,
        previous: [Operation]
    ) -> [Operation] {
        var previous = previous

        if !previous.contains(operation) {
            previous.append(operation)
        }

        let seeds = seeds(of: operation)
        seeds.forEach { $0.addDependency(operation) }

        return seeds.reduce(previous) {
            traverse(operation: $1, previous: $0)
        }
    }
}
