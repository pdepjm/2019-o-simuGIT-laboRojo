class Carpeta {
	const nombre 
	const property archivos = []

	method contieneA(nombreArchivo) = archivos.any{ archivo => 
			archivo.tieneNombre(nombreArchivo)
		}
		
	method nuevoArchivo(nombreArchivo) {
		archivos.add(new Archivo(nombre = nombreArchivo))
	}
	
	method eliminarArchivo(nombreArchivo) {
		archivos.remove(self.obtenerArchivo(nombreArchivo))
	}
	
	method obtenerArchivo(nombreArchivo) = archivos.find{ archivo => 
			archivo.tieneNombre(nombreArchivo)
		}
}

class Archivo {
	var property nombre
	var property contenido = ""
	
	method tieneNombre(nombreArchivo) = nombre == nombreArchivo
	
	method agregarContenido(texto) {
		contenido = contenido + texto
	}
	
	method sacarContenido(texto) {
		if (contenido.endsWith(texto))
			contenido = contenido.takeLeft(contenido.size() - texto.size())
	}
}

class Commit {
	const descripcion
	const cambios = []
	
	method agregarCambio(cambio) {
		cambios.add(cambio)
	}
	
	method aplicarCambios(carpeta) {
		cambios.forEach{ cambio =>
			cambio.aplicarSobre(carpeta)
		}
	}
	
	method afectaA(nombreArchivo) = cambios.any{ cambio => cambio.afectaA(nombreArchivo)}

	method revert() = new Commit(
		descripcion = "revert " + descripcion,
		cambios = cambios.map({cambio => cambio.opuesto()}).reverse()
	)
}


class Cambio {
	const nombreArchivo

	method aplicarSobre(carpeta) {
		self.validarArchivo(carpeta)
		self.aplicarCambio(carpeta)
	}
	
	method aplicarCambio(carpeta)

	method opuesto()
	
	method validarArchivo(carpeta) {
		if (not carpeta.contieneA(nombreArchivo))
			self.error("El archivo "+ nombreArchivo +" no existe")
	}
	
	method afectaA(_nombreArchivo) = _nombreArchivo == nombreArchivo
	
}

class Crear inherits Cambio {

	override method aplicarCambio(carpeta) {
		carpeta.nuevoArchivo(nombreArchivo)
	}
	
	override method validarArchivo(carpeta) {
		if (carpeta.contieneA(nombreArchivo))
			self.error("No se puede crear porque el archivo "+ nombreArchivo +" ya existe")		
	}
	
	override method opuesto() = new Eliminar(nombreArchivo = nombreArchivo)
	
}

class Eliminar inherits Cambio {
	override method aplicarCambio(carpeta) {
		carpeta.eliminarArchivo(nombreArchivo)
	}
	
	override method opuesto() = new Crear(nombreArchivo = nombreArchivo)
	
}

//TODO: Se podría abstraer una clase intermedia (para Agregar y Sacar) que sea CambioEnArchivo
class Agregar inherits Cambio {
	const texto
	
	override method aplicarCambio(carpeta) {
		carpeta
		.obtenerArchivo(nombreArchivo)
		.agregarContenido(texto)
	}
	
	override method opuesto() = new Sacar(
		nombreArchivo = nombreArchivo,
		texto = texto
	)
	
}

class Sacar inherits Cambio {
	const texto
	
	override method aplicarCambio(carpeta) {
		carpeta
		.obtenerArchivo(nombreArchivo)
		.sacarContenido(texto)
	}

	override method opuesto() = new Agregar(
		nombreArchivo = nombreArchivo,
		texto = texto
	)
}


class Branch {
	const commits = []
	const colaboradores = []
	
	method commitear(usuario, commit) {
		if (not usuario.tienePermiso(self))
			self.error("No tenés permisos para commitear")
			
		self.agregarCommit(commit)
	}
	
	method agregarCommit(commit) {
		commits.add(commit)
	}
	
	method checkout(carpeta) {
		commits.forEach({commit =>
			commit.aplicarCambios(carpeta)
		})
	}
	
	method esColaborador(usuario) = colaboradores.contains(usuario)
	
	method log(nombreArchivo) = commits.filter{commit => commit.afectaA(nombreArchivo)}
	
	method blame(nombreArchivo) = self.log(nombreArchivo).map({commit => commit.autor()})
}

class Usuario {
	var property rol
	
	method tienePermiso(branch) = rol.tienePermisoPara(branch, self)
	
	method convertirA(otroUsuario, unRol) {
		rol.convertirA(otroUsuario, unRol)
	}
}

object admin {
	method tienePermisoPara(branch, usuario) = true
	
	method convertirA(otroUsuario, unRol) {
		otroUsuario.rol(unRol)
	}
}

object comun {
	method tienePermisoPara(branch, usuario) = branch.esColaborador(usuario)
	
	method convertirA(otroUsuario, unRol) {
		self.error("No podés convertilo porque sos un pichi")
	}
}