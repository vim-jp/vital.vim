package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"strings"

	vimlparser "github.com/haya14busa/go-vimlparser"
	"github.com/haya14busa/go-vimlparser/ast"
	"github.com/haya14busa/go-vimlparser/token"
)

const usageMessage = "" +
	`Usage:	go run ./scripts/lint-throw.go [flags] files...
	# Files must be vital module files under autoload/vital/__vital__/
	# Working directory must be the root of vital.vim repository.

	lint-throw.go checks throw error message format. The messages must be start
	with "vital: {module-name}:"
`

func usage() {
	fmt.Fprintln(os.Stderr, usageMessage)
	fmt.Fprintln(os.Stderr, "Flags:")
	flag.PrintDefaults()
}

func main() {
	flag.Usage = usage
	flag.Parse()
	if err := run(os.Stdout, flag.Args()); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(w io.Writer, files []string) error {
	if len(files) == 0 {
		usage()
	}

	for _, file := range files {
		if err := lintFile(w, file); err != nil {
			return err
		}
	}
	return nil
}

func lintFile(w io.Writer, fname string) error {
	file, err := os.Open(fname)
	if err != nil {
		return err
	}
	defer file.Close()

	opt := &vimlparser.ParseOption{}
	f, err := vimlparser.ParseFile(file, file.Name(), opt)
	if err != nil {
		return err
	}

	moduleName := toModuleName(file.Name())
	wantPrefix := fmt.Sprintf("vital: %s:", moduleName)
	warningMsg := fmt.Sprintf("use `%s` prefix to throw message", wantPrefix)

	ast.Inspect(f, func(node ast.Node) bool {
		switch node := node.(type) {
		case *ast.Throw:
			lintThrowMsg(w, node.Expr, file.Name(), wantPrefix, warningMsg)
		}
		return true
	})

	return nil
}

func lintThrowMsg(w io.Writer, node ast.Expr, filename, wantPrefix, warningMsg string) {
	switch expr := node.(type) {
	case *ast.BasicLit:
		if expr.Kind == token.STRING {
			if !strings.HasPrefix(expr.Value[1:], wantPrefix) {
				fmt.Fprintf(w, "%s:%d:%d: %s", filename, node.Pos().Line, node.Pos().Column, warningMsg+"\n")
			}
		}
	case *ast.CallExpr:
		if fname, ok := expr.Fun.(*ast.Ident); ok && fname.Name == "printf" {
			if len(expr.Args) != 0 {
				lintThrowMsg(w, expr.Args[0], filename, wantPrefix, warningMsg)
			}
		}
	case *ast.BinaryExpr:
		lintThrowMsg(w, expr.Left, filename, wantPrefix, warningMsg)
	}
}

func toModuleName(path string) string {
	const (
		prefix = "autoload/vital/__vital__/"
		suffix = ".vim"
	)
	n := path
	n = n[len(prefix) : len(n)-len(suffix)]
	n = strings.Replace(n, "/", ".", -1)
	return n
}
