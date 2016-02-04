import Foundation

class NodeRouter: RouterDriver {
    
    class Node {
        var nodes = [String: Node]()
        var handler: (Request -> Response)? = nil
    }
    var rootNode = Node()
    
    /**
        Registers a handler into the routing tree. 
        The `Request.Method` is combined with the path
        to create a tree as shown below.
     
            GET      POST
             | \     / | \
             1  2   3  4  5
            / \
           6   7
     
        Ex: GET 1/6, POST 3
     
    */
    func register(method: Request.Method, path: String, handler: (Request -> Response)) {
        let paths = [method.rawValue] + path.split("/")
        self.inflate(self.rootNode, paths: paths).handler = handler
        
        //self.printTree()
    }
    
    
    /**
        Recurses the routing tree to return nodes for assigning
        handlers and create child nodes where needed.
    */
    func inflate(node: Node, var paths: [String]) -> Node {
        if paths.count == 0 {
            return node
        }
        
        let path = paths.removeFirst()
        let child: Node
        
        if let existing = node.nodes[path] {
            child = existing
        } else {
            child = Node()
            node.nodes[path] = child
        }
        
        return self.inflate(child, paths: paths)
    }
    
    /**
        Prints out the routing tree for debugging.
    */
    func printTree() {
        print("\n\n# Tree\n")
        self.printNode(self.rootNode, depth: 0)
    }
    
    /**
        Recurses the routing tree to print
        out nodes at varying depths.
    */
    func printNode(node: Node, depth: Int) {
        for (key, node) in node.nodes {
            var prefix = ""
            for var i = 0; i < depth; i++ {
                prefix += "\t"
            }
            print("\(prefix)\(key)")
            self.printNode(node, depth: depth + 1)
        }
    }

    
    func route(request: Request) -> (Request -> Response)? {
        let paths = [request.method.rawValue] + request.path.split("/")
        
        if let handler = self.search(self.rootNode, paths: paths, request: request) {
            return handler
        }
        
        return nil
    }
  
    
    private func search(node: Node, var paths: [String], request: Request) -> (Request -> Response)? {
        if paths.count == 0 {
            return node.handler
        }
        
        let path = paths.removeFirst()
        
        //find any children of this node with `:variable` keys
        let variableNodes = node.nodes.filter { (key, node) in
            return key.characters.first == ":"
        }
        
        var child: Node?
        
        if let variableNode: (key: String, node: Node) = variableNodes.first {
            //get rid of `:`
            var key = variableNode.key
            key.removeAtIndex(key.startIndex)
            
            request.parameters[key] = path
            child = variableNode.1
        } else if let pathNode = node.nodes[path] {
            child = pathNode
        } else if let startNode = node.nodes["*"] {
            child = startNode
        }
        
        if let child = child {
            return self.search(child, paths: paths, request: request)
        }

        return nil
    }
}
