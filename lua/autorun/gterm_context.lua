AddCSLuaFile()

properties.Add( "use_gterminal",
{
	MenuLabel	=	"Use GTeminal",
	Order		=	1200,
	MenuIcon	=	"icon16/application_xp_terminal.png",

	Filter		=	function( self, ent, ply )
						if (scripted_ents.IsBasedOn(ent:GetClass(), "sent_computer_base")) then
                            return true
                        else
                            return false
                        end
					end,

	Action		=	function( self, ent )
						self:MsgStart()
							net.WriteEntity( ent )
						self:MsgEnd()
					end,

	Receive		=	function( self, length, player )
						local ent = net.ReadEntity()
						local alents = ents.FindByClass("sent_computer*")
						if scripted_ents.IsBasedOn(player:GetEntityInUse(), "sent_computer_base") then
							return
						end
						for b,k in pairs(alents) do
							if IsValid(k:GetUser()) then return end
						end
						ent:Use(player, player, USE_ON, 0)
					end

}) 